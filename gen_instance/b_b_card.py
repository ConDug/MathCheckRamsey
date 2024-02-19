import math
import csv
import copy

def generate_edge_clauses(X, lower, upper, start_var, cnf_file):

    start_var=start_var+len(X)+1#first len(X) vars will be used for root
    class Node():
        counter=0 #Nodes count from 1... may not be needed
        var_counter=start_var
        def __init__(self, key,val):
            self.key=key
            self.value=int(val)
            self.left=math.floor(self.value/2)
            self.right=self.value-self.left
            Node.counter+=1
            self.variables=list(range(Node.var_counter,Node.var_counter+self.value))
            Node.var_counter+=self.value

    class Leaf():
        value=1
        left=None
        right=None
        counter_leaf=0 #Leaves count from 1
        def __init__(self, key):
        self.key=key
        self.variables=[X[Leaf.counter_leaf]]#needs to be  alist of iteration purposes
        Leaf.counter_leaf+=1 
        
        
    class Root():
        key='0'
        def __init__(self, val):
            self.value=int(val)
            self.left=math.floor(self.value/2)
            self.right=self.value-self.left
            self.variables=list(range(start_var-len(X),start_var))#root uses first len(X) vars, output vars in paper
            
    class Tree():
        def __init__(self, val):
            self.nodes = {}
            self.key='0'
            self.val=val
        
            self.add_root(self.val)     
            self.split(self.key,self.val)
            
        def add_node(self, key,val):
        self.nodes[key]=Node(key,val)
        
        def add_root(self,val):#need separate as dont want its variables
        self.nodes['0']=Root(val)
    
        def add_leaf(self, key):
        self.nodes[key]=Leaf(key)
        
        def split(self,key,value):
            if math.floor(value/2)>1:
                self.add_node(key+'0',math.floor(value/2))
                self.split(key+'0',math.floor(value/2))
            elif math.floor(value/2)==1:
                self.add_leaf(key+'0')
                
            if value-math.floor(value/2)>1:
                self.add_node(key+'1',value-math.floor(value/2))
                self.split(key+'1',value-math.floor(value/2))
                #print(key,value)
            elif value-math.floor(value/2)==1:
                self.add_leaf(key+'1')
                #print(key,value)

    tree_n=Tree(len(X))

    clauses=[]
for node in tree_n.nodes:
    #print(node) #-node is the key
    if ff.nodes[node].value>1: #ignore leaves
        #print(ff.nodes[node].variables)
        sigma=copy.deepcopy(ff.nodes[node].variables)
        sigma.append('T')
        alpha=copy.deepcopy(ff.nodes[node+'0'].variables)
        alpha.append('T')
        beta=copy.deepcopy(ff.nodes[node+'1'].variables)
        beta.append('T')

        [clauses.append(gen_implication_clause({a,b},{r})) for a in alpha for b in beta for r in sigma]

        sigma=copy.deepcopy(ff.nodes[node].variables)
        sigma.append('F')
        alpha=copy.deepcopy(ff.nodes[node+'0'].variables)
        alpha.append('F')
        beta=copy.deepcopy(ff.nodes[node+'1'].variables)
        beta.append('F')

        [clauses.append(gen_implication_clause({r},{a,b})) for a in alpha for b in beta for r in sigma]
clauses = [i for i in clauses if i is not None]

for i in range(len(X)):
    if i<=lower-1:#-1 as i starts from 0, but lower starts from 1
        clauses.append(tree_n.nodes['0'].variables[i])
    elif i>upper-1:
        clauses.append(-tree_n.nodes['0'].variables[i])

print('Clauses added: ',len(clauses))

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
