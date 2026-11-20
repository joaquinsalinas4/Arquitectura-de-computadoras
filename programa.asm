# Programa de prueba
        addi x1, x0, 5        # x1 = 5
        addi x2, x0, 10       # x2 = 10
        add  x3, x1, x2       # x3 = 15
        sub  x4, x2, x1       # x4 = 5
        sw   x3, 0(x0)        # mem[0] = 15
        lw   x5, 0(x0)        # x5 = mem[0]
        beq  x4, x1, fin      # salta (x4 == x1)
        addi x6, x0, 99       # no se ejecuta
fin:    slli x7, x1, 3
        halt
