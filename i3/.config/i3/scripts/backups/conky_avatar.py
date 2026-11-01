#!/bin/python3

import os
import random

def change_file():
    path = '/home/flightman/Pictures/wallpapers/avatars/'
    items = os.listdir(path)
    avatar = random.choice(items)
    old_file = path+avatar
    new_file = path+'avatar.jpg'
    if old_file == new_file:
        change_file()
    else:
        return old_file, new_file
old_file, new_file = change_file()

cmd = 'cp ' + old_file + ' ' + new_file
os.system(cmd)


