from PIL import Image

def inverser_niveaux_de_gris(image_path):
    # Ouvrir l'image
    img = Image.open(image_path)

    # Convertir l'image en niveaux de gris si elle ne l'est pas déjà
    img = img.convert('L')

    # Récupérer les dimensions de l'image
    largeur, hauteur = img.size

    # Parcourir chaque pixel de l'image
    for y in range(hauteur):
        for x in range(largeur):
            # Récupérer la valeur du niveau de gris du pixel
            valeur_gris = img.getpixel((x, y))

            # Inverser la valeur du niveau de gris (255 - valeur_gris)
            nouvelle_valeur_gris = 255 - valeur_gris

            # Mettre à jour le pixel avec la nouvelle valeur de gris
            img.putpixel((x, y), nouvelle_valeur_gris)

    # Sauvegarder l'image modifiée
    nom_sortie = image_path
    img.save(nom_sortie)

    print(f"Image avec niveaux de gris inversés enregistrée sous : {nom_sortie}")

# Exemple d'utilisation
chemin_image = 'C:/Users/simon/Zomboid/Workshop/Zomboid Forge/images/ZomboidForge.png'
inverser_niveaux_de_gris(chemin_image)
