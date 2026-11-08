#!/usr/bin/python3

import enchant

wdlst = [ "Hall", "chai", "morge"]
dic = enchant.Dict("smj_NO")
for wd in wdlst:
    dic.check(wd)
    print("input word = {0}, Suggestions => {1}".format(wd, dic.suggest(wd)))
