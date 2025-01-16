def get_ramsey_number(p, q):
    # Store known Ramsey numbers in a dictionary
    # Format: (p,q): R(p,q)
    ramsey_numbers = {
        (1,1): 1, (1,2): 1, (1,3): 1, (1,4): 1, (1,5): 1,
        (1,6): 1, (1,7): 1, (1,8): 1, (1,9): 1, (1,10): 1,
        (2,2): 2, (2,3): 3, (2,4): 4, (2,5): 5, (2,6): 6,
        (2,7): 7, (2,8): 8, (2,9): 9, (2,10): 10,
        (3,3): 6, (3,4): 9, (3,5): 14, (3,6): 18, (3,7): 23,
        (3,8): 28, (3,9): 36,
        (4,4): 18
    }
    
    # Add symmetric cases
    for (p1,q1), value in list(ramsey_numbers.items()):
        ramsey_numbers[(q1,p1)] = value
        
    return ramsey_numbers.get((p,q))

def calculate_strict_bounds(n, p, q):
    # Calculate lower bound: n - R(p, q-1)
    r_p_qm1 = get_ramsey_number(p, q-1)
    if r_p_qm1 is None:
        raise ValueError(f"R({p},{q-1}) is not known")
    lower = n - r_p_qm1
    
    # Calculate upper bound: R(p-1, q) - 1
    r_pm1_q = get_ramsey_number(p-1, q)
    if r_pm1_q is None:
        raise ValueError(f"R({p-1},{q}) is not known")
    upper = r_pm1_q - 1
    
    return lower, upper 