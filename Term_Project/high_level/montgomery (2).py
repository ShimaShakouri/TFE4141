def mont_multiplication(a, b, n, k = 256):
    #Calculates the montgomery multiplication of a and b :a*b*r**-1 mod n
    assert n%2 != 0, 'check n is an odd number'
    if k == None:    
        k = n.bit_length()
    u = 0

    for i in range(0, k):
        if (a & (1<<i)):
            u = u + b

        if (u & 1): #Test if u is odd
            u = u + n
        u = u >> 1

    if u >= n: # Subtracts if u is equal or larger to n, as u mod n should be between 0 and n-1
        u = u - n

    return u

a=2
b=8
n=15
mult=mont_multiplication(a,b,n,4)
print(mult)

def monexponentiation(M, e, n):
    #Calculates M**e mod n using montgomery method
    assert n%2 != 0, 'n must be an odd number'

    k = 256
    r = 2**k
    r_2 = r**2 % n

    # Convert to montgomery 
    M_ = mont_multiplication(M, r_2, n)
    x_ = mont_multiplication(1, r_2, n)

    for i in range(k-1, -1, -1): #Loop from msb to lsp
        x_ = mont_multiplication(x_, x_, n)
        if (e & (1<<i)):
            x_ = mont_multiplication(M_, x_, n)



    # Convert from montgomery form to normal
    x = mont_multiplication(x_, 1, n)
    return x

M=7
e=10
n=15
exp=monexponentiation(M,e,n)
print(exp)
