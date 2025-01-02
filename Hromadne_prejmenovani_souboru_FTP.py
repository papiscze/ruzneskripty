#Skript uprauje soubory na FTP
# 123456_URBINOIVrepaintpack_rar.2e8b40bc9e5f3379f76e03939e6365b1 -> URBINOIVrepaintpack.rar
from ftplib import FTP
import re

# Připojení k FTP serveru
ftp_host = ""
ftp_user = ""
ftp_password = ""
ftp_directory = ""

# Regulární výraz pro odstranění prefixu (čísla + podtržítko)
prefix_pattern = r"^\d+_"

# Regulární výraz pro odstranění přebytků za příponou (rar, zip, exe, atd.)
suffix_pattern = r"(_(rar|zip|exe|7z|hof|scs|RAR|ZIP|hof|rwp))\.[a-f0-9]+$"

# Připojení k FTP serveru
ftp = FTP(ftp_host)
ftp.login(ftp_user, ftp_password)
ftp.cwd(ftp_directory)

print(f"Připojeno k FTP serveru: {ftp_host}")
print(f"Pracuji s adresářem: {ftp_directory}")

# Získání seznamu souborů
files = ftp.nlst()

# Iterace přes soubory na serveru
for filename in files:
    print(f"Zpracovávám soubor: {filename}")
    
    # Odstranění prefixu (čísla + podtržítko)
    new_filename = re.sub(prefix_pattern, "", filename)
    
    # Použití regulárního výrazu k odstranění přebytečných částí a vrácení správné přípony
    new_filename = re.sub(suffix_pattern, r".\2", new_filename)  # Změna na správnou příponu
    
    if filename != new_filename:
        try:
            ftp.rename(filename, new_filename)
            print(f"Přejmenováno: {filename} -> {new_filename}")
        except Exception as e:
            print(f"Chyba při přejmenování {filename}: {e}")
    else:
        print(f"Žádný přebytek nenalezen: {filename}")

# Odhlášení z FTP
ftp.quit()
print("Odpojeno od FTP serveru.")
