
def check_termination(filepath):
    with open(filepath, 'r') as f:
        for line in f:
            if 'Normal termination of Gaussian ' in line:
                return True
    print('{} did not terminate correctly!'.format(filepath))
    return False

