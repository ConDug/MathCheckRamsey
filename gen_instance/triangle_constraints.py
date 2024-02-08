import itertools
import math
import csv


def gen_implication_clause(a,b):
    clause=[]
    if 'F' in a or 'T' in b: #whole clause is T if any variable in is T
        pass
    else:
        for i in a:
            if  i == 'T': #False variables in a DNF dont contribute.... does this give upper though??
                continue
            else:
                clause.append(str(-(i)))#pattern in the 4 clauses, a is always -ive
        for j in b:
            if j == 'F':
                continue
            else:
                clause.append(str(j))#pattern in the 4 clauses, b is always +ive
        #clause.append("0"+"\n")
        return(clause)

 

# Generate clauses encoding that between lower and upper variables in X are assigned true (using sequential counters)
def generate_triangle_clauses(X, upper, start_var, cnf_file,colour):
    #global total_vars
    clauses = []
    total_vars=start_var
    X=sorted(X)
    n = len(X)
    missing_v = list(set(range(1,n+3)) - set(X))
    k = upper+1
    if colour=='b':
        mult=1
    else: mult=-1

    edge_dict={}
    edge_counter=0
    for j in range(1, n+3):             #generating the edge variables
        for i in range(1, j):
            edge_counter += 1
            edge_dict[(i,j)] = edge_counter
            edge_dict[(j,i)] = edge_counter
    #print(edge_dict)

    S = [[0 for j in range(k+1)] for i in range(n+1)]

    for i in range(n+1):
        S[i][0] = 'T'

    for j in range(1, k+1):
        S[0][j] = 'F'


    S[n][k] = 'F' #upper +1 is F

    # Define new auxiliary variables (and updates the global variable total_vars)
    for i in range(n+1):
        for j in range(k+1):
            if S[i][j] == 0:
                total_vars += 1
                S[i][j] = total_vars

 
    #from GitHub for degs, slightly different to paper. Should be diff, cant remember exactly where
    #({S[i-1][j]}, {S[i][j]}))
    #({X[i-1], S[i-1][j-1]}, {S[i][j]})) 
    #({S[i][j]}, {S[i-1][j], X[i-1]})) -> gets split into 2 as clause is A->B OR (C AND D)
    #({S[i][j]}, {S[i-1][j-1]}))

    # Generate clauses encoding cardinality constraint
    for i in range(1, n+1):
        for j in range(1, k+1):
            #clauses.append(gen_implication_clause({S[i-1][j]}, {S[i][j]}))
            #clauses.append(gen_implication_clause({mult*edge_dict[(X[i-1],missing_v[0])],mult*edge_dict[(X[i-1],missing_v[1])], S[i-1][j-1]}, {S[i][j]}))
            #clauses.append(gen_implication_clause({S[i][j]}, {S[i-1][j], mult*edge_dict[(X[i-1],missing_v[0])]}))
            #clauses.append(gen_implication_clause({S[i][j]}, {S[i-1][j], mult*edge_dict[(X[i-1],missing_v[1])]}))
            #clauses.append(gen_implication_clause({S[i][j]}, {S[i-1][j-1]}))
            edge_0=edge_dict[(missing_v[0],missing_v[1])]
            edge_1=edge_dict[(X[i-1],missing_v[0])]
            edge_2=edge_dict[(X[i-1],missing_v[1])]
            clauses.append(gen_implication_clause({mult*edge_0,S[i-1][j]}, {S[i][j]}))
            clauses.append(gen_implication_clause({mult*edge_0,mult*edge_1,mult*edge_2, S[i-1][j-1]}, {S[i][j]}))
            clauses.append(gen_implication_clause({mult*edge_0,S[i][j]}, {S[i-1][j], mult*edge_1}))
            clauses.append(gen_implication_clause({mult*edge_0,S[i][j]}, {S[i-1][j], mult*edge_2}))
            clauses.append(gen_implication_clause({mult*edge_0,S[i][j]}, {S[i-1][j-1]}))
    clauses = [i for i in clauses if i is not None]
    
    
    clause_count=0  
    cnf = open(cnf_file, 'a+')
    for clause in clauses:
        string_lst = []
        for var in clause:
            string_lst.append(str(var))
        string = ' '.join(string_lst)
        #print(string)
        cnf.write(string + " 0\n")
        clause_count += 1
    
    return(total_vars,clause_count)
