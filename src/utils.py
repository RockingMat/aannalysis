import csv


def read_csv_dict(path):
    data = []
    with open(path, "r") as f:
        reader = csv.DictReader(f)
        for line in reader:
            data.append(line)
    return data


def belongingness(tup1, tup2):
    """is tup1 contained in tup2?"""
    assert tup1[0] <= tup1[1] and tup2[0] <= tup2[1]

    if tup2[0] <= tup1[0] and tup2[1] >= tup1[1]:
        return True
    else:
        return False
