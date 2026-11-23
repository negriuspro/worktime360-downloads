# WorkTime 360 — Descargas para Android

Este repositorio solo distribuye el APK oficial de **WorkTime 360** para Android.
No contiene el código fuente de la aplicación.

- **Usar WorkTime 360 sin instalar nada:** https://worktime360.vercel.app/bienvenida/
- **Descargar siempre la última versión:**
  https://github.com/negriuspro/worktime360-downloads/releases/latest/download/WorkTime360.apk
- **Todas las versiones:** https://github.com/negriuspro/worktime360-downloads/releases

No necesitas una cuenta de GitHub para descargar.

## Comprobar que el archivo es el oficial

Cada versión publica la huella SHA-256 del APK en sus notas y en la página de bienvenida.
Compárala con la del archivo que descargaste:

- **Windows (PowerShell):** `Get-FileHash .\WorkTime360.apk -Algorithm SHA256`
- **macOS / Linux:** `shasum -a 256 WorkTime360.apk`

Si las huellas no coinciden, no instales el archivo.

## Publicar una versión nueva (solo el mantenedor)

En **PowerShell**, desde esta carpeta y con el APK de la versión nueva ya compilado:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\publicar-apk.ps1 -Apk "C:\ruta\al\app-release.apk" -Version 1.2.2 -Notas "Qué cambió de verdad" -Prueba
```

Con `-Prueba` solo revisa y muestra qué publicaría. Si todo está bien, repite el comando sin `-Prueba`.

El script calcula la huella, crea el release `v<versión>` con el archivo `WorkTime360.apk`
y lo marca como el más reciente, así que el enlace de "última versión" pasa a apuntar a él.
Se niega a publicar si la versión ya existe, si ese mismo APK ya está publicado con otro número
o si las notas son el texto de ejemplo. Cambia solo `gh` a la cuenta dueña del repositorio y
al terminar deja activa la que estaba. Requiere [GitHub CLI](https://cli.github.com/) con esa
cuenta registrada.
