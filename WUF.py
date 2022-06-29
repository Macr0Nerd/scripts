from typing import TypeVar, Generic, Dict, List, Set

T = TypeVar('T')


class WUF(Generic[T]):
    """This class implements the Weighted Union Find (WUF) data structure.

    This data structure is an implementation of a disjoint-set structure, which organizes data into independent groups.
    This can be used to determine if two points on a graph are connected, or if there are cycles in an undirected graph
    that has no self loops.

    .. important::

        This is a generic class meaning that the key type will need to be specified, such as WUF[int].
        This generic type will be denoted as T henceforth.

    .. note::

        This implementation does utilize path compression.
    """

    Pair = List[T, int]
    """A data type used to combine the root and size information into a single location."""

    def __init__(self, tree: Dict[T, Pair] = None):
        """initializes the WUF instance

        Initializes the tree with a key type of T that corresponds to a pair with root of that index and its size.

        :param self: self
        :param tree: the tree structure to construct the WUF from
        :type tree: dict[T, [T, int]]
        """
        if not tree:
            tree = {}

        self.tree: Dict[T, WUF.Pair] = tree
        """Used to store the WUF tree with the student ID and it's corresponding root information."""

    def __iter__(self):
        """returns the tree iterable

        :param self: self
        :returns: the tree iterator
        """
        return self.tree.__iter__()

    def add_root(self, uid: T) -> bool:
        """returns the success of adding the root

        Adds a new root to the tree with its root set to self (meaning it's top level) and with a size of one.

        :param self: self
        :param uid: the Student ID to add to the tree
        :type uid: T
        :returns: whether the operation succeeded
        :rtype: bool
        """
        if uid not in self.tree:
            self.tree[uid] = [uid, 1]
            return True

        return False

    def get_root(self, uid: T) -> T:
        """returns the root of the union the id is in

        This function traverses the tree in order to find the root of the union that ID is a part of.

        :param self: self
        :param uid: the key to retrieve the union for
        :type uid: T
        :returns: the root in the union
        :rtype: T
        """
        if uid not in self.tree:
            raise IndexError(f"{uid} is not in the tree")

        root = uid
        while root != self.tree[root][0]:
            self.tree[root][0] = self.tree[self.tree[root][0]][0]
            root = self.tree[root][0]

        return root

    def get_root_groups(self) -> Dict[T, set[T]]:
        """returns the tree in the format of root groups

        This function will parse the tree and return it as root groups such that the top level roots are the dictionary
        keys and a list of UIDs is the value.

        :param self: self
        :returns: the root group version of the tree
        :rtype: dict[T, list[T]]
        """
        rootGroups: Dict[T, Set[T]] = {}

        for key in self.tree:
            root: str = self.get_root(key)

            if root not in rootGroups:
                rootGroups[root] = set()

            rootGroups[root].add(key)

        return rootGroups

    def union(self, p: T, q: T) -> None:
        """unions two items in the tree

        Unions data in the tree using the WUF algorithm.
        If the size of q's root union is greater than the size of p's root union, then add p to q.
        Otherwise, q will be added to p.

        :param self: Self
        :param p: the first item to union
        :param q: the second item to union
        :type p: T
        :type q: T
        """

        pRoot = self.get_root(p)
        qRoot = self.get_root(q)

        if pRoot == qRoot:
            return

        if self.tree[qRoot][1] > self.tree[pRoot][1]:
            self.tree[pRoot][0] = qRoot
        else:
            if self.tree[pRoot][1] == self.tree[qRoot][1]:
                self.tree[pRoot][1] += self.tree[qRoot][1]

            self.tree[qRoot][0] = pRoot
