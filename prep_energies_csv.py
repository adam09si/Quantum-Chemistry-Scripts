#!/usr/local/bin/python3
# -*- coding: latin-1 -*-

import numpy as np
import pandas as pd

Columns=['Name', 'SCF', 'ZPE', 'Enthalpy', 'Free Energy', 'Free Energy Quasiharmonic', 'Frequencies']

# Load the data in the current directory
df = pd.read_table("Results_p.txt", names=Columns)
dfSP = pd.read_table("SP_files.txt", names=["Name", "SP SCF"])

# Concatenate the dataframes
df["SP SCF"] = dfSP["SP SCF"]

# Calculate the SP corrected energies
df["Corrected ZPE"] = df["SP SCF"] + (df["ZPE"] - df["SCF"])
df["Corrected Enthalpy"] = df["SP SCF"] + (df["Enthalpy"] - df["SCF"])
df["Corrected Free Energy"] = df["SP SCF"] + (df["Free Energy"] - df["SCF"])
df["Corrected Free Energy Quasiharmonic"] = df["SP SCF"] + (df["Free Energy Quasiharmonic"] - df["SCF"])

df.dropna(inplace=True) # deletes all missing data rows

df["∆∆G‡"] = ((df["Corrected Free Energy Quasiharmonic"] - df["Corrected Free Energy Quasiharmonic"].min()) * 627.51)

output = df.sort_values("∆∆G‡")
output.to_csv("output.csv")
