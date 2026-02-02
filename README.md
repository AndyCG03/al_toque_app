
# AlTOQUE 

<p align="center">
  <img src="assets/iconos/baja_calidad.jpg" width="96" />
</p>

Aplicación **Flutter** para consultar tasas de cambio del mercado informal cubano, utilizando datos de la **API de elTOQUE**.

---

## ✨ Características

- ✅ Calculadora de conversión entre múltiples monedas (**CUP, USD, MLC, USDT**, etc.)
- ✅ Tasas actualizadas automáticamente desde la API de **elTOQUE**
- ✅ Funciona **offline** con datos en caché
- ✅ Modo **oscuro / claro**
- ✅ Tasas personalizables

---

## 🚀 Instalación

### 1️⃣ Clonar el repositorio
```bash
git clone https://github.com/AndyCG03/al_toque_app.git
cd al_toque_app
````

### 2️⃣ Configurar variables de entorno

```bash
cp .env.example .env
```

Edita el archivo `.env` y agrega tu **token de la API**
Obtén el token aquí 👉 [https://tasas.eltoque.com/docs/](https://tasas.eltoque.com/docs/)

### 3️⃣ Instalar dependencias

```bash
flutter pub get
```

### 4️⃣ Ejecutar la aplicación

```bash
flutter run
```

---

## 🛠 Requisitos

* Flutter SDK **3.16.0** o superior
* Dart **3.0** o superior
* Token de la API de **tasas.eltoque.com**

---

## 📱 Ejemplo de pantallas

<p align="center">
  <img src="assets/demo.gif" alt="Demo Tasas elTOQUE" width="300">
</p>

---

## 📄 Licencia

MIT License

---

## 🚀 PASO 4: Comandos para subir tu código a GitHub

```bash
# Asegúrate de estar en la carpeta correcta
cd "C:/Almacen/Proyectos/Proyectos Flutter/al_toque/app"

# Verifica el estado del repositorio
git status

# Añade todos los archivos (excepto los del .gitignore)
git add .

# Realiza el commit inicial
git commit -m "Initial commit: Tasas elTOQUE app v1.0"

# Sube a GitHub (si ya configuraste el remote)
git push origin main

# Si el repositorio remoto no existe o da error
git remote set-url origin https://github.com/AndyCG03/al_toque_app.git
git push -u origin main
```

