chcp 65001 | Out-Null
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

Add-Type -AssemblyName System.Windows.Forms

# =========================================== NO TOCAR ===========================================

                                                function Save-Manifest {
                                                    $dialog = New-Object System.Windows.Forms.SaveFileDialog
                                                    $dialog.Title  = "Guardar el manifiesto en"
                                                    $dialog.FileName = "manifiesto"           
                                                    $dialog.Filter = "Manifest SHA512 (*.sha512.manifest)|*.sha512.manifest"
                                                    $dialog.InitialDirectory = [Environment]::GetFolderPath("Desktop") # Carpeta inicial opcional

                                                    if ($dialog.ShowDialog() -eq "OK") { return $dialog.FileName }
                                                    return $null
                                                }
# ================================================================================================= 

# ======== VENTANTAS EXCLUSIVAS DE GENERAR MANIFIESTO 1 archivo ========
function Seleccionar_archivo_unico_del_que_generar_manifiesto {
    $dialog = New-Object System.Windows.Forms.OpenFileDialog
    $dialog.Title = "Selecciona un único archivo del que generaremos el manifiesto"
    $dialog.Filter = "Todos los archivos (*.*)|*.*"
    $dialog.InitialDirectory = [Environment]::GetFolderPath("Desktop") # Carpeta inicial opcional
    if ($dialog.ShowDialog() -eq "OK") { return $dialog.FileName }
    return $null
}

# ✅ ================ GENERAR MANIFIESTO 1 archivo ================
function Generate-Manifest-SingleFile {
    Clear-Host
    
    Write-Host "[PETICIÓN] Por favor, seleccione el archivo del que quieres generar un manifiesto." -ForegroundColor Cyan

    $FilePath = Seleccionar_archivo_unico_del_que_generar_manifiesto # Selección de archivo

    # Si el usuario cancela
    if (-not $FilePath) 
    {
        Write-Host "[INFO] Se ha cerrado la ventana de selección del archivo, volviendo a abrir..." -ForegroundColor Yellow
        $FilePath = Seleccionar_archivo_unico_del_que_generar_manifiesto

        if (-not $FilePath) 
        {
            Write-Host "[ERROR] ❌ Se ha cerrado la ventana de selección del archivo de nuevo. Volviendo al menú principal..." -ForegroundColor Yellow
            return
        }
    }
    # Comprobamos que el archivo existe
    if (-not (Test-Path $FilePath -PathType Leaf)) {
        Write-Host "[ERROR] ❌ El archivo no existe. Volviendo al menú..." -ForegroundColor Red
        return
    }

    Write-Host "[OK] ✅ El archivo ha sido seleccionado correctamente." -ForegroundColor Green
    Write-Host ""
    Write-Host "[PETICIÓN] Por favor, seleccione el sitio donde se va a guardar y el nombre del archivo manifiesto." -ForegroundColor Cyan

    $ManifestPath = Save-Manifest # Pedimos dónde guardar el manifiesto

    # Este path incluye tambien el nombre del manifest, por lo tanto si queremos verificar que la ruta seleccionada existe, no nos vale... Tenemos que quitarle el nombre

    if (-not $ManifestPath) {
        Write-Host "[INFO] Se ha cerrado la ventana de selección de carpeta y nombre para guardar el archivo manifiesto., volviendo a abrir..." -ForegroundColor Yellow
        $ManifestPath = Save-Manifest # abrir de nuevo

        if (-not $ManifestPath) {
            Write-Host "[ERROR] ❌ Se ha cerrado la ventana de selección de carpeta y nombre para guardar el archivo manifiesto. Volviendo al menú principal..." -ForegroundColor Red
            return
        }
    }

    # tal y como dijimos en el comentario anterior, vamos a coger el manifestpath y quitarle el nombre del archivo manifest... para verificar que la ruta exista...
    $directorio = Split-Path $ManifestPath -Parent

    if (-not (Test-Path $directorio -PathType Container)) 
    {
        Write-Host "[ERROR] ❌ El directorio seleccionado no existe." -ForegroundColor Red
        return
    }
    Write-Host "[OK] ✅ La ubicación para guardar el manifiesto ha sido seleccionada correctamente." -ForegroundColor Green
    Write-Host ""
    Write-Host "[INFO] Generando manifiesto del archivo especificado..."
    Write-Host "[INFO] Este proceso puede tardar dependiendo del tamaño del archivo, NO CIERRE ESTA VENTANA."
    Write-Host "[INFO] Para archivos de 70 GB aproximadamente unos 10 minutos, si usas HDD."


    # Obtenemos hash
    $file = Get-Item $FilePath
    $hash = (Get-FileHash $file.FullName -Algorithm SHA512).Hash

    # Creamos el manifiesto
    Set-Content -Path $ManifestPath -Encoding UTF8 -Value @(
        "ROOT=."
        "SHA512"
        "$($file.Name)|$hash"
    )
    
    Write-Host "[OK] ✅ El archivo manifiesto se ha creado correctamente." -ForegroundColor Green
    Write-Host "[INFO] El archivo manifiesto se encuentra en: " $ManifestPath
    Write-Host "[INFO] Y el manifiesto se ha creado del archivo original: " $file
    Write-Host ""

    Proteger_manifiesto_sea_de_1_arch_o_carpeta -ManifestPath $ManifestPath # Proteger el manifiesto.
}
# ==============================================================








# ======== VENTANTAS EXCLUSIVAS DE GENERAR MANIFIESTO una carpeta ========
function GENERATE_Select-Folder {

    Add-Type -AssemblyName System.Windows.Forms

    $dialog = New-Object System.Windows.Forms.OpenFileDialog
    $dialog.Title = "Selecciona la carpeta raíz de lo que quieras crear un manifiesto con todos sus archivos"
    $dialog.Filter = "Carpeta|*.*"
    $dialog.CheckFileExists = $false
    $dialog.CheckPathExists = $true
    $dialog.ValidateNames = $false
    $dialog.Multiselect = $false
    $dialog.InitialDirectory = [Environment]::GetFolderPath("Desktop") # Carpeta inicial opcional


    # Truco CLAVE: nombre ficticio
    $dialog.FileName = "Seleccionar carpeta"

    if ($dialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
        return Split-Path $dialog.FileName -Parent
    }

    return $null
}



# ✅ ================ GENERAR MANIFIESTO 1 carpeta ================
function Generate-Manifest-Folder {
    Clear-Host
    
    Write-Host "[PETICIÓN] Por favor, seleccione carpeta raíz de lo que quieres generar un manifiesto." -ForegroundColor Cyan

    $FolderPath = GENERATE_Select-Folder  # Selección de archivo

    if (-not $FolderPath) 
    {
        Write-Host "[INFO] Se ha cerrado la ventana de selección de carpeta, volviendo a abrir..." -ForegroundColor Yellow
        $FolderPath = GENERATE_Select-Folder

        if (-not $FolderPath) 
        {
            Write-Host "[ERROR] ❌ Se ha cerrado la ventana de selección de carpeta de nuevo. Volviendo al menú principal..." -ForegroundColor Yellow
            return
        }
    }
    
    if (-not (Test-Path $FolderPath -PathType Container)) {
        Write-Host "[ERROR] ❌ La ruta a la carpeta no existe o está rota. Volviendo al menú..." -ForegroundColor Red
        return
    }

    Write-Host "[OK] ✅ La carpeta ha sido seleccionada correctamente." $FolderPath -ForegroundColor Green
    Write-Host ""
    Write-Host "[PETICIÓN] Por favor, seleccione el sitio donde se va a guardar y el nombre del archivo manifiesto." -ForegroundColor Cyan

    $ManifestPath = Save-Manifest # Pedimos dónde guardar el manifiesto

    if (-not $ManifestPath) {
        Write-Host "[INFO] Se ha cerrado la ventana de selección de carpeta y nombre para guardar el archivo manifiesto. Volviendo a abrir..." -ForegroundColor Yellow
        $ManifestPath = Save-Manifest # abrir de nuevo

        if (-not $ManifestPath) {
            Write-Host "[ERROR] ❌ Se ha cerrado la ventana de selección de carpeta y nombre para guardar el archivo manifiesto. Volviendo al menú principal..." -ForegroundColor Red
            return
        }
    }




    $rootPath = $FolderPath.TrimEnd('\','/')

    Set-Content -Path $ManifestPath -Encoding UTF8 -Value @(
        "ROOT=."
        "SHA512"
    )

    
    $files = Get-ChildItem $FolderPath -Recurse -File | Where-Object { $_.FullName -ne $ManifestPath } # y que ignore tambien el manifiesto, en caso de haberlo guardado en la misma carpeta en la que se va a realizar los hashes de las cosas, para que el propio manifiesto no se incluya a si mismo

    $total = $files.Count
    $current = 0

    foreach ($file in $files) {
        $current++
        $percent = [math]::Round(($current / $total) * 100)

        Write-Progress `
            -Activity "Generando manifiesto..." `
            -Status "$current de $total" `
            -PercentComplete $percent

        $relPath = $file.FullName.Substring($rootPath.Length).TrimStart('\','/')
        $hash = (Get-FileHash $file.FullName -Algorithm SHA512).Hash

        Add-Content -Path $ManifestPath -Encoding UTF8 -Value "$relPath|$hash"
    }

    Write-Progress -Activity "Generando manifiesto..." -Completed

    Write-Host ""
    Write-Host "[OK] ✅ Manifiesto de carpeta creado correctamente." -ForegroundColor Green
    Write-Host "[INFO] Archivos procesados: $total" -ForegroundColor Cyan
    Write-Host ""

    Proteger_manifiesto_sea_de_1_arch_o_carpeta -ManifestPath $ManifestPath

}
# ==============================================================









# ✅ ==========================================================
function Proteger_manifiesto_sea_de_1_arch_o_carpeta {

    Write-Host "[INFO] Protegiendo el archivo manifiesto... "

    # Quitar herencia
    icacls "$ManifestPath" /inheritance:r | Out-Null

    # Limpiar permisos peligrosos... No ponemos Everyone ni Guests por lo mismo, vaya a ser que en otro idioma 
    # se llame de otra forma. (usando SID)

    icacls "$ManifestPath" /remove "*S-1-1-0" | Out-Null      # Everyone
    icacls "$ManifestPath" /remove "*S-1-5-32-546" | Out-Null # Guests

    # Conceder lectura al grupo Usuarios usamos SID porque a veces es Users otras Usuarios, etc. (SID portable)
    icacls "$ManifestPath" /grant "*S-1-5-32-545:(R)" | Out-Null

    # Atributo extra
    attrib +R "$ManifestPath"

    Write-Host "[OK] ✅ Manifiesto protegido y además es portable (lectura para usuarios)" -ForegroundColor Green
    Write-Host "[INFO] Ya que debemos de poder leer con otros usuarios de otros ordenadores." -ForegroundColor DarkGreen
    Write-Host "[INFO] o en caso de formatear el ordenador creador del manifiesto." -ForegroundColor DarkGreen
}
# ==========================================================










                                                function VERIFY_Select-ManifestFile {
                                                    $dialog = New-Object System.Windows.Forms.OpenFileDialog
                                                    $dialog.Title = "Selecciona el archivo manifiesto para verificar"
                                                    $dialog.InitialDirectory = [Environment]::GetFolderPath("Desktop")          # Carpeta inicial opcional
                                                    $dialog.Filter = "Manifiestos SHA512 (*.sha512.manifest)|*.sha512.manifest" # Solo archivos manifiesto
                                                    if ($dialog.ShowDialog() -eq "OK") { return $dialog.FileName }
                                                    return $null
                                                }
function VERIFY_Select-File {
    $dialog = New-Object System.Windows.Forms.OpenFileDialog
    $dialog.Title = "Selecciona el archivo actual que quieras verificar"
    $dialog.InitialDirectory = [Environment]::GetFolderPath("Desktop")          # Carpeta inicial opcional
    $dialog.Filter = "Todos los archivos (*.*)|*.*"
    if ($dialog.ShowDialog() -eq "OK") { return $dialog.FileName }
    return $null
}

# ====================== verify ============================
# =============== verify un único archivo ==================
function Verify-SingleFileIntegrity {
    Clear-Host

    Write-Host "[PETICIÓN] Por favor, seleccione el archivo manifiesto para verificar" -ForegroundColor Cyan

    $ManifestPath = VERIFY_Select-ManifestFile

    if (-not $ManifestPath) # CUANDO ES NULL
    {
        Write-Host "[ERROR] ❌ Acabas de cerrar la ventana para seleccionar el archivo manifiesto." -ForegroundColor Red
        Write-Host "[INFO] Abriendo de nuevo..."
        Write-Host ""

        $ManifestPath = VERIFY_Select-ManifestFile # Para abrirlo de nuevo, vaya a ser que el usuario le haya dado sin querer...

        if (-not $ManifestPath) # CUANDO ES NULL
        {
        Write-Host "[ERROR] ❌ Acabas de volver a cerrar ventana para seleccionar el archivo manifiesto." -ForegroundColor Red
        Write-Host "[INFO] Redirigiendo al menú principal..."
        return # Detenerlo en caso de que sea NULL es decir, si el usuario ha cerrado la ventanita esa.
        }
    }

    if (-not (Test-Path $ManifestPath)) # CUANDO SI TIENE VALOR, PERO COMPRUEBA QUE LA RUTA EXISTA REALMENTE
    { 
        Write-Host "[ERROR] ❌ Manifiesto no encontrado o la ruta hacia el manfiesto está rota." -ForegroundColor Red
        return # No sigue adelante, se sale de la funcion
    }
    
    Write-Host ""
    Write-Host "[INFO] Ruta del manifiesto seleccionada:" $ManifestPath
    Write-Host ""

    # ============================== leer el archivo: ===================================

    
    $lineas = Get-Content $ManifestPath -TotalCount 4 | Where-Object { $_.Trim() -ne "" }
    $total_lineas = $lineas.Count


    # LA COMPROBACIÓN DE SI EL ARCHIVO ES PARA UN MANIFIEST PARA UN ARCHIVO ÚNICO.
    # Como siempre van a estar las 2 primeras lineas en el manifiesto hagas lo que hagas
    # sin importar cuantos hashes haya dentro...
    # Entonces el mínimo mínimo siempre será 3 líneas en total, para solo un archivo.
    if ($total_lineas -eq 3) # == Entonces si es 3, que es el minimo minimo guay.
    {
        # ============================================== VERIFICACIÓN DEL MANIFIESTO ===============================================

        Write-Host "[COMPROBACIÓN] ✅ Manifiesto ES de archivo único." -ForegroundColor Green
        Write-Host "[CONFIRMACIÓN] Total de líneas: $total_lineas" -ForegroundColor Yellow
        Write-Host ""

        # Ahora que ya sabemos que el total de lineas son 3, por lo tanto, no es mucho, podemos almacenar cada linea en un array.

        $contenido = @() # Creamos un array vacio.

        $contenido = Get-Content $ManifestPath

        Write-Host "[INFO] Almacenando contenido del fichero en un array:"
        Write-Host ""
        Write-Host "[COMPROBACIÓN] El algoritmo del hash es: " $contenido[1] -ForegroundColor Yellow


        if ($contenido[1] -ne "SHA512") {
            Write-Host "[ERROR] ❌ El manifiesto no es válido. La segunda línea no indica SHA512." -ForegroundColor Red
            return  # Esto detiene la ejecución de la función inmediatamente
        }
        Write-Host "[CONFIRMACIÓN] ✅ Algoritmo válido." -ForegroundColor Green
        Write-Host ""
        Write-Host "[INFO] Empezando la verificación del hash con el archivo."
        Write-Host "[INFO] Obteniendo el hash del manifiesto..."
        # ============================================== COGER EL HASH DEL MANIFIESTO ===============================================
        $hash_manifiesto = $contenido[2].Split('|')[1].Trim()

        Write-Host "[COMPROBACIÓN] El hash del manifiesto es:" -ForegroundColor Yellow
        Write-Host $hash_manifiesto -ForegroundColor Yellow
        Write-Host ""

        # ============================================== COGER EL HASH del archivo actual ===============================================
        Write-Host "[PETICIÓN] Selecciona el archivo a verificar:" -ForegroundColor Cyan

        $archivo_actual = VERIFY_Select-File

        if (-not $archivo_actual) # CUANDO ES NULL
        {
            Write-Host "[ERROR] ❌ Acabas de cerrar la ventana para seleccionar el archivo que queremos verificar." -ForegroundColor Red
            Write-Host "[INFO] Abriendo de nuevo..."
            Write-Host ""

            $archivo_actual = VERIFY_Select-File # Para abrirlo de nuevo, vaya a ser que el usuario le haya dado sin querer...

            if (-not $archivo_actual) # CUANDO ES NULL
            {
                Write-Host "[ERROR] ❌ Acabas de volver a cerrar ventana para seleccionar el archivo que queremos verificar." -ForegroundColor Red
                Write-Host "[INFO] Redirigiendo al menú principal..."
                return # Detenerlo en caso de que sea NULL es decir, si el usuario ha cerrado la ventanita esa.
            }
        }



        if (-not (Test-Path $archivo_actual)) {
            Write-Host "[ERROR] ❌ El archivo seleccionado no existe." -ForegroundColor Red
            return
        }
        
        Write-Host "[OK] ✅ Archivo seleccionado correctamente: " $archivo_actual -ForegroundColor Green
        Write-Host ""   
        Write-Host "[INFO] Realizando hasheo del archivo seleccionado..."    
        Write-Host "[INFO] Este proceso puede tardar dependiendo del tamaño del archivo, NO CIERRE ESTA VENTANA."
        Write-Host "[INFO] Para archivos de 70 GB aproximadamente unos 10 minutos, si usas HDD."
        Write-Host ""


        $hash_actual = (Get-FileHash $archivo_actual -Algorithm SHA512).Hash

        Write-Host "[COMPROBACIÓN] El hash del archivo actual es:" -ForegroundColor Yellow
        Write-Host $hash_actual -ForegroundColor Yellow
        Write-Host ""

        $nombre_del_archivo_en_manifiesto = ($contenido[2] -split '\|')[0]  
        $nombre_archivo_seleccionado = Split-Path $archivo_actual -Leaf

        Write-Host "[INFO] Realizando la comprobación de integridad..."
        if ($hash_actual -eq $hash_manifiesto) {
            Write-Host "[OK] ✅ INTEGRIDAD CORRECTA: el archivo NO ha sido modificado." -ForegroundColor Green
            Write-Host "[COMPROBACIÓN] Archivo seleccionado: " $nombre_archivo_seleccionado -ForegroundColor Yellow
            Write-Host "[COMPROBACIÓN] Archivo original del manifiesto: " $nombre_del_archivo_en_manifiesto -ForegroundColor Yellow
            Write-Host ""

        }
        else {
            Write-Host "[ERROR] ❌ El archivo ha sido modificado o has seleccionado un archivo erróneo" -ForegroundColor Red
            Write-Host "[INFO] Mostrando el nombre del archivo actual seleccionado y el nombre del archivo que está en el manifiesto..."
            Write-Host "[INFO] En caso de NO coincidir, es posible también que se haya modificado el nombre del archivo y que además haya sido modificado el contenido."
            Write-Host "[INFO] En caso de NO coincidir, es posible que hayas seleccionado un archivo que no es."
            Write-Host "[COMPROBACIÓN] Archivo original del manifiesto: " $nombre_del_archivo_en_manifiesto -ForegroundColor Yellow
            Write-Host "[COMPROBACIÓN] Archivo seleccionado: $nombre_archivo_seleccionado" -ForegroundColor Yellow

            if ($nombre_del_archivo_en_manifiesto -eq $nombre_archivo_seleccionado) {
                Write-Host "[CONFIRMACIÓN] El nombre si era el mismo, el archivo ha sido modificado." -ForegroundColor Red
                Write-Host ""

            }else {
                Write-Host "[CONFIRMACIÓN] El nombre NO era el mismo, el archivo que seleccionaste probablemente fuera el erróneo" -ForegroundColor Yellow
                Write-Host ""

            }
        }

    }
    elseif ($total_lineas -lt 3) # menor (mal)
    {
        Write-Host "[COMPROBACIÓN] ❌ Manifiesto roto o no has seleccionado un manifiesto" -ForegroundColor Red
        Write-Host "[CONFIRMACIÓN] Total de líneas: $total_lineas"
        Write-Host "[INFO] Compruebe manualmente el manifiesto"
        Write-Host ""
    }
    elseif ($total_lineas -gt 3) # mayor que (mal)
    {
        Write-Host "[COMPROBACIÓN] ❌ Manifiesto no es de archivo único. Tiene múltiples hashes" -ForegroundColor Red
        Write-Host "[CONFIRMACIÓN] Total de líneas: $total_lineas"
        Write-Host "[INFO] Compruebe manualmente el manifiesto"
        Write-Host ""
    }


    Write-Host "Para volver al principal menú PULSA ENTER."  -ForegroundColor Yellow
    Read-Host
    Clear-Host
}




# ESTO ES PARA LA OPCION DE VERIFICACION DE INTEGRIDAD, La segunda ventanita de selecionar la carpeta raíz del manifiesto.

function VERIFY_Select-ManifestRootFolder {

    Add-Type -AssemblyName System.Windows.Forms

    $dialog = New-Object System.Windows.Forms.OpenFileDialog
    $dialog.Title = "Seleccionar la carpeta raíz que contiene los archivos del manifiesto"
    $dialog.Filter = "Carpeta|*.*"
    $dialog.CheckFileExists = $false
    $dialog.CheckPathExists = $true
    $dialog.ValidateNames = $false
    $dialog.Multiselect = $false
    $dialog.InitialDirectory = [Environment]::GetFolderPath("Desktop") # Carpeta inicial opcional


    # Truco CLAVE: nombre ficticio
    $dialog.FileName = "Seleccionar carpeta"

    if ($dialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
        return Split-Path $dialog.FileName -Parent
    }

    return $null
}
# ================= verify una carpeta =====================
function Verify-FolderIntegrity {
    Clear-Host

    Write-Host "[PETICIÓN] Por favor, seleccione el archivo manifiesto para veritifcar" -ForegroundColor Cyan
    
    $ManifestPath = VERIFY_Select-ManifestFile

    if (-not $ManifestPath) # CUANDO ES NULL
    {
        Write-Host "[ERROR] ❌ Acabas de cerrar la ventana para seleccionar el archivo manifiesto." -ForegroundColor Red
        Write-Host "[INFO] Abriendo de nuevo..."
        Write-Host ""

        $ManifestPath = VERIFY_Select-ManifestFile # Para abrirlo de nuevo, vaya a ser que el usuario le haya dado sin querer...

        if (-not $ManifestPath) # CUANDO ES NULL
        {
        Write-Host "[ERROR] ❌ Acabas de volver a cerrar ventana para seleccionar el archivo manifiesto." -ForegroundColor Red
        Write-Host "[INFO] Redirigiendo al menú principal..."
        return # Detenerlo en caso de que sea NULL es decir, si el usuario ha cerrado la ventanita esa.
        }
    }

    if (-not (Test-Path $ManifestPath)) # CUANDO SI TIENE VALOR, PERO COMPRUEBA QUE LA RUTA EXISTA REALMENTE
    { 
        Write-Host "[ERROR] ❌ Manifiesto no encontrado o la ruta hacia el manfiesto está rota." -ForegroundColor Red
        return # No sigue adelante, se sale de la funcion
    }
    
    Write-Host "[OK] ✅ Ruta del manifiesto seleccionada:" $ManifestPath -ForegroundColor Green
    Write-Host ""
    Write-Host ""
    Write-Host "[PETICIÓN] Selecciona la carpeta donde se encuentra AHORA la raíz del manifiesto:" -ForegroundColor Cyan

    $rootPath = VERIFY_Select-ManifestRootFolder

    if (-not $rootPath) # CUANDO ES NULL
    {
        Write-Host "[ERROR] ❌ Acabas de cerrar la ventana para seleccionar la carpeta raíz donde se encuentran los archivos del manifiesto." -ForegroundColor Red
        Write-Host "[INFO] Abriendo de nuevo..."
        Write-Host ""

        $rootPath = VERIFY_Select-ManifestRootFolder # Para abrirlo de nuevo, vaya a ser que el usuario le haya dado sin querer...

        if (-not $rootPath) # CUANDO ES NULL
        {
        Write-Host "[ERROR] ❌ Acabas de volver a cerrar ventana para seleccionar la carpeta raíz donde se encuentran los archivos del manifiesto." -ForegroundColor Red
        Write-Host "[INFO] Redirigiendo al menú principal..."
        return # Detenerlo en caso de que sea NULL es decir, si el usuario ha cerrado la ventanita esa.
        }
    }

    if (-not (Test-Path $rootPath)) # CUANDO SI TIENE VALOR, PERO COMPRUEBA QUE LA RUTA EXISTA REALMENTE
    { 
        Write-Host "[ERROR] ❌ Ruta no encontrada o la ruta está rota." -ForegroundColor Red
        return # No sigue adelante, se sale de la funcion
    }

    # Cargar manifiesto
    $manifestFiles = @{}
    $lines = Get-Content $ManifestPath | Select-Object -Skip 2
    foreach ($line in $lines) {
        if (-not $line.Trim()) { continue }
        $parts = $line -split '\|', 2
        if ($parts.Count -ne 2) { continue }
        $relPath = $parts[0].TrimStart('\','/')
        $hash    = $parts[1].Trim()
        $manifestFiles[$relPath] = $hash
    }

    $okFiles   = @()
    $modFiles  = @()
    $delFiles  = @()
    $newFiles  = @()
    $movedFiles = @()

    $total = $manifestFiles.Count
    $current = 0

    Write-Host ""
    foreach ($relPath in $manifestFiles.Keys) {
        $current++
        $percent = [math]::Round(($current / $total) * 100)
        Write-Progress -Activity "Verificando integridad de archivos..." -Status "$current de $total" -PercentComplete $percent

        $absPath = Join-Path $rootPath $relPath
        if (Test-Path $absPath) {
            $hash = (Get-FileHash $absPath -Algorithm SHA512).Hash
            if ($hash -eq $manifestFiles[$relPath]) {
                $okFiles += $relPath
            }
            else {
                $modFiles += $relPath
            }
        }
    }

    # Archivos actuales
    $allCurrentFiles = Get-ChildItem $rootPath -Recurse -File | ForEach-Object {
        $_.FullName.Substring($rootPath.Length).TrimStart('\','/')
    }

    foreach ($relFile in $allCurrentFiles) {
        if (-not $manifestFiles.ContainsKey($relFile)) {
            $absFile = Join-Path $rootPath $relFile
            $hash = (Get-FileHash $absFile -Algorithm SHA512).Hash

            $match = $manifestFiles.GetEnumerator() |
                     Where-Object { $_.Value -eq $hash } |
                     Select-Object -First 1

            if ($match) {
                $movedFiles += "$($match.Key) -> $relFile"
            }
            else {
                $newFiles += $relFile
            }
        }
    }

    $originalMoved = $movedFiles | ForEach-Object { ($_ -split ' -> ')[0] }
    foreach ($relPath in $manifestFiles.Keys) {
        $absPath = Join-Path $rootPath $relPath
        if (-not (Test-Path $absPath) -and ($originalMoved -notcontains $relPath)) {
            $delFiles += $relPath
        }
    }

    Write-Progress -Activity "Verificación completada" -Completed

    # RESULTADOS
    if ($modFiles.Count) {
        Write-Host "`nArchivos modificados:" -ForegroundColor Red
        $modFiles | ForEach-Object { Write-Host $_ -ForegroundColor Red }
    }

    if ($delFiles.Count) {
        Write-Host "`nArchivos eliminados:" -ForegroundColor Yellow
        $delFiles | ForEach-Object { Write-Host $_ -ForegroundColor Yellow }
    }

    if ($movedFiles.Count) {
        Write-Host "`nArchivos movidos:" -ForegroundColor Magenta
        $movedFiles | ForEach-Object { Write-Host $_ -ForegroundColor Magenta }
    }

    if ($newFiles.Count) {
        Write-Host "`nArchivos nuevos:" -ForegroundColor Cyan
        $newFiles | ForEach-Object { Write-Host $_ -ForegroundColor Cyan }
    }

    Write-Host "`n===== RESUMEN =====" -ForegroundColor Cyan
    Write-Host "OK:           $($okFiles.Count)" -ForegroundColor Green
    Write-Host "Modificados:  $($modFiles.Count)" -ForegroundColor Red
    Write-Host "Eliminados:   $($delFiles.Count)" -ForegroundColor Yellow
    Write-Host "Movidos:      $($movedFiles.Count)" -ForegroundColor Magenta
    Write-Host "Nuevos:       $($newFiles.Count) [No contarlos en el total del manifiesto]" -ForegroundColor Cyan
    Write-Host "Total de archivos en el manifiesto: $($manifestFiles.Count)"
}
# ==========================================================











# ==================== INSTRUCCIONES =============================
function instrucciones_1_programa {
    # ==================== PRIMERA PARTE: TEORÍA =============================
    Clear-Host
    Write-Host "===== GENERAR MANIFIESTO DE INTEGRIDAD =====`n" -ForegroundColor Cyan
    Write-Host "Este es el primer paso para verificar la integridad de los archivos"
    Write-Host "Es decir, para saber si han sido modificados/corrompidos, de forma"
    Write-Host "intencionada o no intencionada."
    Write-Host ""
    Write-Host ""
    Write-Host "Este paso DEBE OMITIRSE en caso de ya tener un archivo manifiesto."
    Write-Host "Y proceder con el paso 2. Que es el de verificar el manifiesto que ya"
    Write-Host "tendríamos que tener, con los archivos en el estado actual en el que estén"
    Write-Host ""
    Write-Host ""
    Write-Host "De esta forma se comprobará mediante comparación de: lo nuevo VS lo antiguo"
    Write-Host "Si ha sido modificado."
    Write-Host ""
    Write-Host ""
    Write-Host "Para resumir, este proceso genera un hash para cada archivo, no carpetas."
    Write-Host "Los hashes son una cadena aleatoria de números y letras, generada de manera puramente matemática"
    Write-Host "Es tan aleatoria que jamás podrían coincidir los hashes de dos archivos diferentes..."
    Write-Host ""
    Write-Host "Por ejemplo: el hash del libro del quijote VS el hash del libro de shakespeare... Jamás coincidirá"
    Write-Host "La aleatoriedad se base en el contenido de un archivo, es decir,"
    Write-Host "si tuviéramos dos archivos del libro del Quijote"
    Write-Host "Pues lógicamente, el hash sería el mismo, pues el Quijote no cambia, es el mismo libro."
    Write-Host "El hash SÓLO se basa en el contenido de un archivo, NO en su nombre, metadatos, tamaño, ubicación."
    Write-Host ""
    Write-Host ""
    Write-Host "Entonces, todos estos hashes los almacena todos en un archivo llamado `"manifiesto`" "
    Write-Host "cuya extensión del archivo es `".sha512.manifest`", y cuyo algoritmo matemático es SHA-512"
    Write-Host ""
    Write-Host ""
    Write-Host "Este archivo NO puede ser modificado de manera fácil, requiere de conocimiento técnico. "
    Write-Host "Aunque se puede."
    Write-Host ""
    Write-Host "Finalmente, la auténtica linea de defensa está en las copias de seguridad."
    Write-Host "Aunque se corrompan archivos, y este programa que estés usando nos diga "
    Write-Host "que se han modificado o eliminado archivos, no podemos hacer nada para recuperarlos."
    Write-Host "Este programa NO recupera archivos, solo señala lo que falta y lo modificado."
    Write-Host "Eres tú quien tiene que recuperarlos."
    Write-Host ""
    Write-Host ""
    Write-Host "Pues una de las propiedades matemáticas además de la aleatoriedad por el contenido, es que este proceso es irreversible."
    Write-Host "Esto quiere decir que dado un hash `"a87n21masd8x12...`" jamás podrás obtener el archivo físico "
    Write-Host "dado ese mismo hash. Que por irónico que parezca, tú has generado ese hash del archivo."
    Write-Host ""
    Write-Host "Sencillamente es una función matemática tan compleja que imposibilita su reversibilidad y no por la incapacidad de nuestros"
    Write-Host "ordenadores actuales y/o a futuro, si no, porque está a propósito hecho así."
    Write-Host ""
    Write-Host "De no haber sido creada de esta manera la función matemática, habría brechas de seguridad de dos pares de cojones. Y la integridad y hashes"
    Write-Host "son los pilares actuales principales y fundamentales de la ciberseguridad, junto con otros pilares."
    Write-Host ""
    Write-Host ""
    Write-Host "Para ello, están las copias de seguridad, es prácticamente imposible que en varios discos duros se produzca"
    Write-Host "el mismo problema. Que se borre algo o se modifique algo."
    Write-Host "Eso quiere decir que obtendremos/recuperaremos los archivos que nos faltan de las copias de seguridad y las añadiremos a donde nos falte."
    Write-Host ""
    Write-Host ""
    Write-Host "Cuando continúes:"
    Write-Host "- Elegirás un archivo o una carpeta del que quieras generar el manifiesto (el archivo que recopila 1 o muchos hashes)."
    Write-Host "- Deberás elegir la ubicación donde se guardará el manifiesto, que contendrá el o los hashes."
    Write-Host "- Se creará un archivo MANIFIESTO que almacenará el o los hashes de manera automática."
    Write-Host "- Ese manifiesto se protegerá automáticamente`n"
    Write-Host ""
    Write-Host "Si ya has leído todo, pulsa ENTER para continuar..." -ForegroundColor Yellow
    Read-Host
    Clear-Host
    
    # ==================== SEGUNDA PARTE: EL SUBMENÚ =============================

    Write-Host "===== GENERADOR DE MANIFIESTO =====`n" -ForegroundColor Cyan

    Write-Host "Dentro del generador de manifiesto tienes dos posibilidades:`n"

    Write-Host "1) Generar manifiesto de UN SOLO ARCHIVO" -ForegroundColor Green
    Write-Host "   - Se calcula el hash únicamente del archivo seleccionado"
    Write-Host "   - Útil para documentos importantes, imágenes sueltas, etc.`n"

    Write-Host "2) Generar manifiesto de UNA CARPETA COMPLETA" -ForegroundColor Green
    Write-Host "   - Incluye todos los archivos de la carpeta"
    Write-Host "   - Incluye subcarpetas y su contenido"
    Write-Host "   - Ideal para colecciones de fotos, documentos, backups, etc."
    Write-Host "   - [NUEVO] Funciona también con carpetas virtuales, como unidades montadas usando VeraCrypt`n"

}
function instrucciones_2_programa {
    # ==================== PRIMERA PARTE: TEORÍA =============================
    Clear-Host
    Write-Host "===== VERIFICAR INTEGRIDAD DE ARCHIVOS =====`n" -ForegroundColor Cyan
    Write-Host "Este proceso compara los archivos actuales con el manifiesto guardado."
    Write-Host "El manifiesto es un archivo que contiene uno o muchos hashes (valores únicos generados a partir del contenido de cada archivo)."
    Write-Host "El manifiesto también guarda la ruta que le corresponde a cada archivo."
    Write-Host "El manifiesto tiene la siguiente estructura:"
    Write-Host "<ruta> | <hash>"
    Write-Host ""
    Write-Host ""
    Write-Host "Cada hash representa el estado exacto del archivo en el momento de crear el manifiesto."
    Write-Host "Si un archivo cambia, mueve, elimina o aparece uno nuevo, el programa lo detectará comparando su hash con los hashes almacenados en el manifiesto."
    Write-Host "o usando la ruta que ha almacenado en el manifiesto y le corresponde a ese hash (En caso de movido o eliminado)"
    Write-Host ""
    Write-Host ""
    Write-Host "Podemos seleccionar 2 modos, verificar un único archivo o una carpeta entera, que podrá contener muchos archivos."
    Write-Host "Dependiendo del modo elegido, el programa verificará diferentes aspectos."
    Write-Host ""
    Write-Host ""
    Write-Host "si elegiste el 1) sólo verificará si el archivo ha sido modificado, mediante su hash. Comparando el del manifiesto y el actual del archivo seleccionado."
    Write-Host "si elegiste el 2) mostrará:"
    Write-Host "   - Una lista de nombrando todos los archivos: movidos, modificados, nuevos y eliminados. Los OK no."
    Write-Host "   - Un resumen mostrando sólo el recuento de todos los archivos: OK, modificados, movidos, eliminados y nuevos."
    Write-Host "   - Un resumen mostrando sólo el recuento de todos los archivos que aparecen en el manifiesto."
    Write-Host ""
    Write-Host "Para leer la teoría completa, sal y pulsa 1 para ver la teoría, "
    Write-Host "SÓLO léela y sal de nuevo, para volver al programa 2"
    Write-Host ""
    Write-Host ""
    Write-Host "Si ya has leído todo, pulsa ENTER para continuar..." -ForegroundColor Yellow
    Read-Host
    Clear-Host 
    # ==================== SEGUNDA PARTE: AVISO =============================
    Write-Host "⚠️  AVISO IMPORTANTE" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Asegúrate de que:" -ForegroundColor Yellow
    Write-Host "- El manifiesto corresponde exactamente a los archivos que quieres verificar." -ForegroundColor Yellow
    Write-Host "- No se están modificando archivos durante la verificación." -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Los resultados solo serán fiables si el entorno es correcto." -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Si estás seguro y deseas continuar con la verificación," -ForegroundColor Yellow
    Write-Host "pulsa ENTER para comenzar..." -ForegroundColor Yellow
    Read-Host
    Clear-Host

    # ==================== TERCERA PARTE: SUBMENÚ =============================
    Write-Host "Dentro de la verificación de archivos tenemos dos opciones:"
    Write-Host ""
    Write-Host "1) Verificar UN SOLO ARCHIVO" -ForegroundColor Green
    Write-Host ""
    Write-Host "2) Verificar CARPETA COMPLETA" -ForegroundColor Green
    Write-Host ""
    Write-Host "Escribe SOLO el número de la opción que deseas utilizar y pulsa ENTER." -ForegroundColor Cyan
}
# ================================================================

# ======================== AVISOS ================================
function programa_1_aviso_opcion_2_carpetas {
    # Aviso importante solo para carpetas en el programa 1, opción 2.
    Clear-Host
    Write-Host "`n⚠️  AVISO IMPORTANTE:" -ForegroundColor Yellow
    Write-Host "No guardes el manifiesto dentro de la misma carpeta que estás seleccionando para generar los hashes." -ForegroundColor Yellow
    Write-Host "Si lo haces, el manifiesto podría incluirse a sí mismo en la generación de hashes y causar errores." -ForegroundColor Yellow
    Write-Host "Ejemplo: Si tu carpeta es T:\Fotos y guardas el manifiesto en T:\Fotos\manifiesto.sha512.manifest," -ForegroundColor Yellow
    Write-Host "aparecerá un error al procesar el manifiesto. Guarda el archivo en otra ubicación, por ejemplo, en T:\Manifiestos." -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Tras finalizar la creación del manifiesto PUEDES GUARDAR el manifiesto donde tu quieras" -ForegroundColor Yellow
    Write-Host ""
    # Esperar a que el usuario lea el aviso
    Write-Host "Si has leido este aviso, pulsa ENTER para continuar..." -ForegroundColor Cyan
    Read-Host
}
# ================================================================











# ======================= BUCLE PRINCIPAL =======================
do {
    Write-Host "`n===== FILE INTEGRITY CHECKER ====="
    Write-Host ""
    Write-Host "1) Generar manifiesto"
    Write-Host "2) Verificar integridad"
    Write-Host "0) Salir"
    Write-Host ""

    Write-Host "Escribe SOLO el número de la opción que deseas utilizar y pulsa ENTER." -ForegroundColor Cyan
    $option = Read-Host "Opción"


    if ($option -notin "0","1","2") {
        Write-Host "`n[ERROR] ❌ Opción no válida. Debes escribir 0, 1 o 2." -ForegroundColor Red
        continue  # vuelve al inicio del bucle mostrando el menú
    }

    switch ($option) {
# ========================== PROGRAMA 1 ==========================
        "1"
        {

            instrucciones_1_programa #texto

            do 
            {
                $Programa_1_subprograma = Read-Host "Opción" #El texto te pide que selecciones una de esas dos opciones aquí lo recogemos.
                
                if ($Programa_1_subprograma -notin "1","2") 
                {
                    Write-Host "[ERROR] ❌ Opción inválida. Debes escribir 1 o 2.`n" -ForegroundColor Red
                }

            }
            while ($Programa_1_subprograma -notin "1","2")  # Sigue preguntando hasta que sea válido

            if ($Programa_1_subprograma -eq "1") 
            {
                Generate-Manifest-SingleFile # Ejecución real del programa
            }
            if ($Programa_1_subprograma -eq "2") 
            {
                programa_1_aviso_opcion_2_carpetas # Texto.             El aviso de que no guardes el manifiesto 
                Generate-Manifest-Folder # Ejecución real del programa
            }


            

        }
# ========================== PROGRAMA 2 ==========================
        "2" 
        {
            instrucciones_2_programa  #texto

            do 
            {

                $verifyMode = Read-Host "Opción"

                # Mensaje de error si es inválido
                if ($verifyMode -notin "1","2") {
                    Write-Host "[ERROR] ❌ Opción inválida. Debes escribir 1 o 2." -ForegroundColor Red
                }

            }
            while ($verifyMode -notin "1","2")  # Sigue preguntando hasta que sea válido

            # Ahora que sabemos que $verifyMode es 1 o 2, solo necesitamos el if / elseif
            if ($verifyMode -eq "1") {
                Verify-SingleFileIntegrity # Ejecución real del programa
            }
            elseif ($verifyMode -eq "2") {
                Verify-FolderIntegrity # Ejecución real del programa
            }
        }

    }
}

while ($option -ne "0")