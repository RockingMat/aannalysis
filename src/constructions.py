import re
import inflect

from dataclasses import dataclass

inflector = inflect.engine()

@dataclass
class AANN:
    article: str
    adjective: str
    numeral: str
    noun: str

    def __post_init__(self):
        self.string = re.sub(
            r"\s{2,}",
            " ",
            f"{self.article} {self.adjective} {self.numeral} {self.noun}",
        ).strip()


# @dataclass
# class AANN:
#     article: str
#     adjective: str
#     numeral: str
#     noun: str

#     def __post_init__(self):
#         if self.article != "":
#             article = inflector.a(f"{self.adjective} {self.numeral}".strip().split(" ")[0]).split(" ")[0]
#         else:
#             article = ""
#         self.string = re.sub(
#             r"\s{2,}",
#             " ",
#             f"{article} {self.adjective} {self.numeral} {self.noun}",
#         ).strip()
