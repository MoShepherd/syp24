from prettytable import PrettyTable

# Tabelle erstellen
tabelle = PrettyTable()
tabelle.field_names = ["r_FIFO_DATA", "Status", "Zustand", "Folgezustand","Beschreibung Folgezustand"]

# Zeilen hinzufügen
tabelle.add_row(["01 00 01", "00 00 04", "z_POWER_ON","z_RUNNING","SVNR in Running Mode"])
tabelle.add_row(["01 00 02", "00 00 02", "z_POWER_ON","z_UPLOAD_TO_RAM","" ])
tabelle.add_row(["xx xx 02", "03 00 13","z_POWER_ON","z_POWER_ON",""])
tabelle.add_row(["01 00 06", "00 00 05", "z_POWER_ON","z_DEBUG_INIT", "" ])
tabelle.add_row(["01 00 05", "00 00 01", "z_POWER_ON","----------", "Hold on"])
tabelle.add_row(["01 00 07", "-- -- --","z_POWER_ON","z_RESETTING","" ])
tabelle.add_row(["", "", "", "", ""])
tabelle.add_row(["01 00 05", "03 00 11","z_UPLOAD_TO_RAM","z_RAM" , ""])
tabelle.add_row(["", "","z_UPLOAD_TO_RAM","" , ""])


# Tabelle drucken
print("Root: z_POWER_ON")
print(tabelle)
