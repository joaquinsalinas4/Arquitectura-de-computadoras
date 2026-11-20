#!/usr/bin/env python3
"""Ensamblador RISC-V (RV32I reducido) + cargador UART para la Debug Unit.

Uso:
    python ensamblador.py programa.asm                      # ensambla y muestra el listado
    python ensamblador.py programa.asm --salida programa.hex # además guarda las palabras en hex
    python ensamblador.py programa.asm --puerto COM3 --baud 19200   # además las envía a la FPGA
"""
import argparse
import re
import struct
import sys

HALT = 0xFFFFFFFF          # marca de fin de carga (la Debug Unit sale de LOAD al recibirla)
CMD_LOAD = b'L'            # comando 'L' de la Debug Unit
ORDEN_BYTES = '>I'         # byte más significativo primero (la Debug Unit desplaza a la izquierda)


class ErrorAsm(Exception):
    pass


# ---------------------------------------------------------------- registros
ABI = {'zero': 0, 'ra': 1, 'sp': 2, 'gp': 3, 'tp': 4, 't0': 5, 't1': 6, 't2': 7,
       's0': 8, 'fp': 8, 's1': 9, 'a0': 10, 'a1': 11, 'a2': 12, 'a3': 13, 'a4': 14,
       'a5': 15, 'a6': 16, 'a7': 17, 's2': 18, 's3': 19, 's4': 20, 's5': 21,
       's6': 22, 's7': 23, 's8': 24, 's9': 25, 's10': 26, 's11': 27,
       't3': 28, 't4': 29, 't5': 30, 't6': 31}


def registro(txt):
    t = txt.strip().lower()
    if t in ABI:
        return ABI[t]
    m = re.fullmatch(r'x(\d+)', t)
    if m and 0 <= int(m.group(1)) <= 31:
        return int(m.group(1))
    raise ErrorAsm(f"registro inválido: '{txt}'")


def numero(txt):
    try:
        return int(txt.strip(), 0)
    except ValueError:
        raise ErrorAsm(f"número inválido: '{txt}'")


# ---------------------------------------------------------------- tablas de instrucciones
# nombre: (formato, opcode, funct3, funct7)
INSTR = {
    # Tipo R
    'add':  ('R', 0b0110011, 0b000, 0b0000000), 'sub':  ('R', 0b0110011, 0b000, 0b0100000),
    'sll':  ('R', 0b0110011, 0b001, 0b0000000), 'slt':  ('R', 0b0110011, 0b010, 0b0000000),
    'sltu': ('R', 0b0110011, 0b011, 0b0000000), 'xor':  ('R', 0b0110011, 0b100, 0b0000000),
    'srl':  ('R', 0b0110011, 0b101, 0b0000000), 'sra':  ('R', 0b0110011, 0b101, 0b0100000),
    'or':   ('R', 0b0110011, 0b110, 0b0000000), 'and':  ('R', 0b0110011, 0b111, 0b0000000),
    # Tipo I aritmético
    'addi':  ('I', 0b0010011, 0b000, None), 'slti': ('I', 0b0010011, 0b010, None),
    'sltiu': ('I', 0b0010011, 0b011, None), 'xori': ('I', 0b0010011, 0b100, None),
    'ori':   ('I', 0b0010011, 0b110, None), 'andi': ('I', 0b0010011, 0b111, None),
    # Desplazamientos con inmediato (tipo I con funct7)
    'slli': ('SH', 0b0010011, 0b001, 0b0000000), 'srli': ('SH', 0b0010011, 0b101, 0b0000000),
    'srai': ('SH', 0b0010011, 0b101, 0b0100000),
    # Cargas
    'lb':  ('L', 0b0000011, 0b000, None), 'lh':  ('L', 0b0000011, 0b001, None),
    'lw':  ('L', 0b0000011, 0b010, None), 'lbu': ('L', 0b0000011, 0b100, None),
    'lhu': ('L', 0b0000011, 0b101, None),
    # jalr
    'jalr': ('JALR', 0b1100111, 0b000, None),
    # Stores
    'sb': ('S', 0b0100011, 0b000, None), 'sh': ('S', 0b0100011, 0b001, None),
    'sw': ('S', 0b0100011, 0b010, None),
    # Saltos condicionales
    'beq': ('B', 0b1100011, 0b000, None), 'bne': ('B', 0b1100011, 0b001, None),
    # U y J
    'lui': ('U', 0b0110111, None, None),
    'jal': ('J', 0b1101111, None, None),
}


# ---------------------------------------------------------------- codificadores
def en_rango(valor, minimo, maximo, que):
    if not (minimo <= valor <= maximo):
        raise ErrorAsm(f"{que} fuera de rango: {valor} (permitido {minimo}..{maximo})")


def cod_R(op, f3, f7, rd, rs1, rs2):
    return (f7 << 25) | (rs2 << 20) | (rs1 << 15) | (f3 << 12) | (rd << 7) | op


def cod_I(op, f3, rd, rs1, imm):
    en_rango(imm, -2048, 2047, 'inmediato de 12 bits')
    return ((imm & 0xFFF) << 20) | (rs1 << 15) | (f3 << 12) | (rd << 7) | op


def cod_S(op, f3, rs1, rs2, imm):
    en_rango(imm, -2048, 2047, 'desplazamiento de 12 bits')
    imm &= 0xFFF
    return ((imm >> 5) << 25) | (rs2 << 20) | (rs1 << 15) | (f3 << 12) | ((imm & 0x1F) << 7) | op


def cod_B(op, f3, rs1, rs2, imm):
    en_rango(imm, -4096, 4094, 'desplazamiento del salto')
    if imm % 2:
        raise ErrorAsm(f"el desplazamiento del salto debe ser par: {imm}")
    imm &= 0x1FFF
    return (((imm >> 12) & 1) << 31) | (((imm >> 5) & 0x3F) << 25) | (rs2 << 20) | (rs1 << 15) \
        | (f3 << 12) | (((imm >> 1) & 0xF) << 8) | (((imm >> 11) & 1) << 7) | op


def cod_U(op, rd, imm):
    en_rango(imm, -(1 << 19), (1 << 20) - 1, 'inmediato de 20 bits')
    return ((imm & 0xFFFFF) << 12) | (rd << 7) | op


def cod_J(op, rd, imm):
    en_rango(imm, -(1 << 20), (1 << 20) - 2, 'desplazamiento del salto')
    if imm % 2:
        raise ErrorAsm(f"el desplazamiento del salto debe ser par: {imm}")
    imm &= 0x1FFFFF
    return (((imm >> 20) & 1) << 31) | (((imm >> 1) & 0x3FF) << 21) | (((imm >> 11) & 1) << 20) \
        | (((imm >> 12) & 0xFF) << 12) | (rd << 7) | op


# ---------------------------------------------------------------- análisis del texto
def limpiar(linea):
    return re.split(r'[#;]', linea, maxsplit=1)[0].strip()


def operandos(txt):
    return [o.strip() for o in txt.split(',')] if txt.strip() else []


def mem_operando(txt):
    """'8(x6)' -> (8, 6)"""
    m = re.fullmatch(r'(.*)\((.+)\)', txt.strip())
    if not m:
        raise ErrorAsm(f"se esperaba el formato desplazamiento(registro), se recibió '{txt}'")
    imm = numero(m.group(1)) if m.group(1).strip() else 0
    return imm, registro(m.group(2))


def valor_o_etiqueta(txt, etiquetas, direccion):
    """Un salto puede ser un número (desplazamiento en bytes) o una etiqueta."""
    t = txt.strip()
    if t in etiquetas:
        return etiquetas[t] - direccion
    return numero(t)


def exigir(ops, n, nombre):
    if len(ops) != n:
        raise ErrorAsm(f"'{nombre}' espera {n} operandos y recibió {len(ops)}")


def ensamblar(texto):
    """Devuelve una lista de (numero_de_linea, texto_original, palabra)."""
    # Pasada 1: separar etiquetas e instrucciones, y calcular la dirección (en bytes) de cada etiqueta
    items, etiquetas = [], {}
    for n, linea in enumerate(texto.splitlines(), 1):
        t = limpiar(linea)
        while True:
            m = re.match(r'^([A-Za-z_]\w*):\s*(.*)$', t)
            if not m:
                break
            if m.group(1) in etiquetas:
                raise ErrorAsm(f"línea {n}: etiqueta repetida '{m.group(1)}'")
            etiquetas[m.group(1)] = len(items) * 4
            t = m.group(2)
        if t:
            items.append((n, linea.strip(), t))

    # Pasada 2: codificar
    salida = []
    for idx, (n, original, t) in enumerate(items):
        direccion = idx * 4
        partes = t.split(None, 1)
        nom = partes[0].lower()
        ops = operandos(partes[1]) if len(partes) > 1 else []
        try:
            salida.append((n, original, codificar(nom, ops, etiquetas, direccion)))
        except ErrorAsm as e:
            raise ErrorAsm(f"línea {n} ('{original}'): {e}")
    return salida


def codificar(nom, ops, etiquetas, direccion):
    if nom == 'nop':
        return cod_I(0b0010011, 0, 0, 0, 0)
    if nom == 'halt':
        return HALT
    if nom not in INSTR:
        raise ErrorAsm(f"instrucción desconocida '{nom}'")
    fmt, op, f3, f7 = INSTR[nom]

    if fmt == 'R':
        exigir(ops, 3, nom)
        return cod_R(op, f3, f7, registro(ops[0]), registro(ops[1]), registro(ops[2]))
    if fmt == 'I':
        exigir(ops, 3, nom)
        return cod_I(op, f3, registro(ops[0]), registro(ops[1]), numero(ops[2]))
    if fmt == 'SH':
        exigir(ops, 3, nom)
        shamt = numero(ops[2])
        en_rango(shamt, 0, 31, 'cantidad de desplazamiento')
        return cod_R(op, f3, f7, registro(ops[0]), registro(ops[1]), shamt)
    if fmt == 'L':
        exigir(ops, 2, nom)
        imm, rs1 = mem_operando(ops[1])
        return cod_I(op, f3, registro(ops[0]), rs1, imm)
    if fmt == 'JALR':
        if len(ops) == 2:
            imm, rs1 = mem_operando(ops[1])
        else:
            exigir(ops, 3, nom)
            rs1, imm = registro(ops[1]), numero(ops[2])
        return cod_I(op, f3, registro(ops[0]), rs1, imm)
    if fmt == 'S':
        exigir(ops, 2, nom)
        imm, rs1 = mem_operando(ops[1])
        return cod_S(op, f3, rs1, registro(ops[0]), imm)
    if fmt == 'B':
        exigir(ops, 3, nom)
        return cod_B(op, f3, registro(ops[0]), registro(ops[1]),
                     valor_o_etiqueta(ops[2], etiquetas, direccion))
    if fmt == 'U':
        exigir(ops, 2, nom)
        return cod_U(op, registro(ops[0]), numero(ops[1]))
    if fmt == 'J':
        exigir(ops, 2, nom)
        return cod_J(op, registro(ops[0]), valor_o_etiqueta(ops[1], etiquetas, direccion))
    raise ErrorAsm(f"formato no soportado para '{nom}'")


def preparar_palabras(listado):
    """Controla el HALT: tiene que estar al final, y una sola vez."""
    palabras = [w for _, _, w in listado]
    for i, w in enumerate(palabras[:-1]):
        if w == HALT:
            raise ErrorAsm(f"'halt' (0xFFFFFFFF) en la instrucción {i}: solo puede ir al final, "
                           "porque la Debug Unit termina la carga al recibirlo")
    if not palabras or palabras[-1] != HALT:
        palabras.append(HALT)
        print("Aviso: el programa no termina en 'halt'; se agregó uno al final.", file=sys.stderr)
    return palabras


# ---------------------------------------------------------------- envío por UART
def enviar(palabras, puerto, baud):
    try:
        import serial          # pyserial: pip install pyserial
    except ImportError:
        raise SystemExit("Falta pyserial: pip install pyserial")
    with serial.Serial(puerto, baud, timeout=1) as ser:
        ser.write(CMD_LOAD)
        for w in palabras:
            ser.write(struct.pack(ORDEN_BYTES, w))
        ser.flush()
    print(f"Enviadas {len(palabras)} palabras ({1 + 4 * len(palabras)} bytes) por {puerto} a {baud} baudios.")


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument('archivo', help='archivo .asm')
    ap.add_argument('--salida', help='guarda las palabras en un archivo de texto (hexadecimal)')
    ap.add_argument('--puerto', help='puerto serie (ej: COM3 o /dev/ttyUSB1); si se omite, no se envía nada')
    ap.add_argument('--baud', type=int, default=19200)
    args = ap.parse_args()

    with open(args.archivo, encoding='utf-8') as f:
        texto = f.read()
    try:
        listado = ensamblar(texto)
        palabras = preparar_palabras(listado)
    except ErrorAsm as e:
        raise SystemExit(f"Error: {e}")

    print(f"{'dir':>5}  {'palabra':<10}  fuente")
    for i, (_, original, w) in enumerate(listado):
        print(f"{i * 4:>5}  {w:08x}    {original}")
    if len(palabras) > len(listado):
        print(f"{len(listado) * 4:>5}  {HALT:08x}    (halt agregado)")

    if args.salida:
        with open(args.salida, 'w') as f:
            f.write('\n'.join(f"{w:08x}" for w in palabras) + '\n')
        print(f"Guardado en {args.salida}")
    if args.puerto:
        enviar(palabras, args.puerto, args.baud)


if __name__ == '__main__':
    main()
