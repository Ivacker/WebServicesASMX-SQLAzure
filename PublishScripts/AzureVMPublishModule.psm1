#  AzureVMPublishModule.psm1 es un módulo de script de Windows PowerShell. Este módulo exporta funciones de Windows PowerShell que automatizan la administración del ciclo de vida para aplicaciones web. Puede usar las funciones como están o personalizarlas para su aplicación y entorno de publicación.

Set-StrictMode -Version 3

# Variable en la que se va a guardar la suscripción original.
$Script:originalCurrentSubscription = $null

# Variable en la que se va a guardar la cuenta de almacenamiento original.
$Script:originalCurrentStorageAccount = $null

# Variable en la que se va a guardar la cuenta de almacenamiento de la suscripción especificada por el usuario.
$Script:originalStorageAccountOfUserSpecifiedSubscription = $null

# Variable en la que se va a guardar el nombre de la suscripción.
$Script:userSpecifiedSubscription = $null

# Número de puerto de Web Deploy
New-Variable -Name WebDeployPort -Value 8172 -Option Constant

<#
.SYNOPSIS
Antepone la hora y la fecha a un mensaje.

.DESCRIPTION
Antepone la hora y la fecha a un mensaje. Esta función está diseñada para mensajes escritos en los flujos Error y Verbose.

.PARAMETER  Message
Especifica los mensajes sin la fecha.

.INPUTS
System.String

.OUTPUTS
System.String

.EXAMPLE
PS C:\> Format-DevTestMessageWithTime -Message "Agregando el archivo $filename al directorio"
2/5/2014 1:03:08 PM - Agregando el archivo $filename al directorio

.LINK
Write-VerboseWithTime

.LINK
Write-ErrorWithTime
#>
function Format-DevTestMessageWithTime
{
    [CmdletBinding()]
    param
    (
        [Parameter(Position=0, Mandatory = $true, ValueFromPipeline = $true)]
        [String]
        $Message
    )

    return ((Get-Date -Format G)  + ' - ' + $Message)
}


<#

.SYNOPSIS
Escribe un mensaje de error utilizando como prefijo la hora actual.

.DESCRIPTION
Escribe un mensaje de error utilizando como prefijo la hora actual. Esta función llama a la función Format-DevTestMessageWithTime para anteponer la hora antes de escribir el mensaje en el flujo Error.

.PARAMETER  Message
Especifica el mensaje de la llamada a un mensaje de error. Puede canalizar la cadena de mensaje a la función.

.INPUTS
System.String

.OUTPUTS
Ninguno. La función escribe en el flujo Error.

.EXAMPLE
PS C:> Write-ErrorWithTime -Message "Failed. Cannot find the file."

Write-Error: 2/6/2014 8:37:29 AM - Failed. Cannot find the file.
 + CategoryInfo     : NotSpecified: (:) [Write-Error], WriteErrorException
 + FullyQualifiedErrorId : Microsoft.PowerShell.Commands.WriteErrorException

.LINK
Write-Error

#>
function Write-ErrorWithTime
{
    [CmdletBinding()]
    param
    (
        [Parameter(Position=0, Mandatory = $true, ValueFromPipeline = $true)]
        [String]
        $Message
    )

    $Message | Format-DevTestMessageWithTime | Write-Error
}


<#
.SYNOPSIS
Escribe un mensaje detallado utilizando como prefijo la hora actual.

.DESCRIPTION
Escribe un mensaje detallado utilizando como prefijo la hora actual. Como llama a Write-Verbose, el mensaje solo se muestra cuando el script se ejecuta con el parámetro Verbose o cuando la preferencia VerbosePreference está establecida en Continue.

.PARAMETER  Message
Especifica el mensaje de la llamada a un mensaje detallado. Puede canalizar la cadena de mensaje a la función.

.INPUTS
System.String

.OUTPUTS
Ninguno. La función escribe en el flujo Verbose.

.EXAMPLE
PS C:> Write-VerboseWithTime -Message "The operation succeeded."
PS C:>
PS C:\> Write-VerboseWithTime -Message "The operation succeeded." -Verbose
VERBOSE: 1/27/2014 11:02:37 AM - The operation succeeded.

.EXAMPLE
PS C:\ps-test> "The operation succeeded." | Write-VerboseWithTime -Verbose
VERBOSE: 1/27/2014 11:01:38 AM - The operation succeeded.

.LINK
Write-Verbose
#>
function Write-VerboseWithTime
{
    [CmdletBinding()]
    param
    (
        [Parameter(Position=0, Mandatory = $true, ValueFromPipeline = $true)]
        [String]
        $Message
    )

    $Message | Format-DevTestMessageWithTime | Write-Verbose
}


<#
.SYNOPSIS
Escribe un mensaje de host utilizando como prefijo la hora actual.

.DESCRIPTION
Esta función escribe un mensaje en el programa host (Write-Host) utilizando como prefijo la hora actual. Los efectos de escribir en el programa host no son siempre iguales. La mayoría de los programas que hospedan Windows PowerShell escriben estos mensajes como salida estándar.

.PARAMETER  Message
Especifica el mensaje base sin fecha. Puede canalizar la cadena de mensaje a la función.

.INPUTS
System.String

.OUTPUTS
Ninguno. La función escribe el mensaje en el programa host.

.EXAMPLE
PS C:> Write-HostWithTime -Message "La operación se realizó correctamente."
1/27/2014 11:02:37 AM - La operación se realizó correctamente.

.LINK
Write-Host
#>
function Write-HostWithTime
{
    [CmdletBinding()]
    param
    (
        [Parameter(Position=0, Mandatory = $true, ValueFromPipeline = $true)]
        [String]
        $Message
    )
    
    if ((Get-Variable SendHostMessagesToOutput -Scope Global -ErrorAction SilentlyContinue) -and $Global:SendHostMessagesToOutput)
    {
        if (!(Get-Variable -Scope Global AzureWebAppPublishOutput -ErrorAction SilentlyContinue) -or !$Global:AzureWebAppPublishOutput)
        {
            New-Variable -Name AzureWebAppPublishOutput -Value @() -Scope Global -Force
        }

        $Global:AzureWebAppPublishOutput += $Message | Format-DevTestMessageWithTime
    }
    else 
    {
        $Message | Format-DevTestMessageWithTime | Write-Host
    }
}


<#
.SYNOPSIS
Devuelve $true si una propiedad o método es miembro del objeto. De lo contrario, $false.

.DESCRIPTION
Devuelve $true si la propiedad o método es miembro del objeto. Esta función devuelve $false para los métodos estáticos de la clase y para las vistas, como PSBase y PSObject.

.PARAMETER  Object
Especifica el objeto de la prueba. Escriba una variable que contenga un objeto o una expresión que devuelva un objeto. No puede especificar tipos, como [DateTime], ni canalizar objetos a esta función.

.PARAMETER  Member
Especifica el nombre de la propiedad o método de la prueba. Si especifica un método, deben omitirse los paréntesis que siguen al nombre del método.

.INPUTS
Ninguno. Esta función no toma datos de entrada de la canalización.

.OUTPUTS
System.Boolean

.EXAMPLE
PS C:\> Test-Member -Object (Get-Date) -Member DayOfWeek
True

.EXAMPLE
PS C:\> $date = Get-Date
PS C:\> Test-Member -Object $date -Member AddDays
True

.EXAMPLE
PS C:\> [DateTime]::IsLeapYear((Get-Date).Year)
True
PS C:\> Test-Member -Object (Get-Date) -Member IsLeapYear
False

.LINK
Get-Member
#>
function Test-Member
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [Object]
        $Object,

        [Parameter(Mandatory = $true)]
        [String]
        $Member
    )

    return $null -ne ($Object | Get-Member -Name $Member)
}


<#
.SYNOPSIS
Devuelve $true si la versión del módulo de Azure es 0.7.4 o posterior. De lo contrario, $false.

.DESCRIPTION
Test-AzureModuleVersion devuelve $true si la versión del módulo de Azure es 0.7.4 o posterior. Devuelve $false si el módulo no está instalado o la versión es anterior. Esta función no tiene parámetros.

.INPUTS
Ninguno

.OUTPUTS
System.Boolean

.EXAMPLE
PS C:\> Get-Module Azure -ListAvailable
PS C:\> #No module
PS C:\> Test-AzureModuleVersion
False

.EXAMPLE
PS C:\> (Get-Module Azure -ListAvailable).Version

Major  Minor  Build  Revision
-----  -----  -----  --------
0      7      4      -1

PS C:\> Test-AzureModuleVersion
True

.LINK
Get-Module

.LINK
PSModuleInfo object (http://msdn.microsoft.com/en-us/library/system.management.automation.psmoduleinfo(v=vs.85).aspx)
#>
function Test-AzureModuleVersion
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [System.Version]
        $Version
    )

    return ($Version.Major -gt 0) -or ($Version.Minor -gt 7) -or ($Version.Minor -eq 7 -and $Version.Build -ge 4)
}


<#
.SYNOPSIS
Devuelve $true si la versión del módulo de Azure instalada es 0.7.4 o posterior.

.DESCRIPTION
Test-AzureModule devuelve $true si la versión instalada del módulo de Azure es 0.7.4 o posterior. Devuelve $false si el módulo no está instalado o la versión es anterior. Esta función no tiene parámetros.

.INPUTS
Ninguno

.OUTPUTS
System.Boolean

.EXAMPLE
PS C:\> Get-Module Azure -ListAvailable
PS C:\> #No module
PS C:\> Test-AzureModule
False

.EXAMPLE
PS C:\> (Get-Module Azure -ListAvailable).Version

Major  Minor  Build  Revision
-----  -----  -----  --------
    0      7      4      -1

PS C:\> Test-AzureModule
True

.LINK
Get-Module

.LINK
PSModuleInfo object (http://msdn.microsoft.com/en-us/library/system.management.automation.psmoduleinfo(v=vs.85).aspx)
#>
function Test-AzureModule
{
    [CmdletBinding()]

    $module = Get-Module -Name Azure

    if (!$module)
    {
        $module = Get-Module -Name Azure -ListAvailable

        if (!$module -or !(Test-AzureModuleVersion $module.Version))
        {
            return $false;
        }
        else
        {
            $ErrorActionPreference = 'Continue'
            Import-Module -Name Azure -Global -Verbose:$false
            $ErrorActionPreference = 'Stop'

            return $true
        }
    }
    else
    {
        return (Test-AzureModuleVersion $module.Version)
    }
}


<#
.SYNOPSIS
Guarda la suscripción de Microsoft Azure actual en la variable $Script:originalSubscription del ámbito de script.

.DESCRIPTION
La función Backup-Subscription guarda la suscripción de Microsoft Azure actual (Get-AzureSubscription -Current) y su cuenta de almacenamiento, así como la suscripción modificada por este script ($UserSpecifiedSubscription) y su cuenta de almacenamiento, en el ámbito de script. Al guardar los valores, puede usar una función, como Restore-Subscription, para restaurar el estado actual de la suscripción y la cuenta de almacenamiento originales si el estado ha cambiado.

.PARAMETER UserSpecifiedSubscription
Especifica el nombre de la suscripción en la que se crearán y publicarán los nuevos recursos. La función guarda los nombres de la suscripción y sus cuentas de almacenamiento en el ámbito de script. Este parámetro es obligatorio.

.INPUTS
Ninguno

.OUTPUTS
Ninguno

.EXAMPLE
PS C:\> Backup-Subscription -UserSpecifiedSubscription Contoso
PS C:\>

.EXAMPLE
PS C:\> Backup-Subscription -UserSpecifiedSubscription Contoso -Verbose
VERBOSE: Backup-Subscription: Start
VERBOSE: Backup-Subscription: Original subscription is Microsoft Azure MSDN - Visual Studio Ultimate
VERBOSE: Backup-Subscription: End
#>
function Backup-Subscription
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [AllowEmptyString()]
        [string]
        $UserSpecifiedSubscription
    )

    Write-VerboseWithTime 'Backup-Subscription: Inicio'

    $Script:originalCurrentSubscription = Get-AzureSubscription -Current -ErrorAction SilentlyContinue
    if ($Script:originalCurrentSubscription)
    {
        Write-VerboseWithTime ('Backup-Subscription: La suscripción original es ' + $Script:originalCurrentSubscription.SubscriptionName)
        $Script:originalCurrentStorageAccount = $Script:originalCurrentSubscription.CurrentStorageAccountName
    }
    
    $Script:userSpecifiedSubscription = $UserSpecifiedSubscription
    if ($Script:userSpecifiedSubscription)
    {        
        $userSubscription = Get-AzureSubscription -SubscriptionName $Script:userSpecifiedSubscription -ErrorAction SilentlyContinue
        if ($userSubscription)
        {
            $Script:originalStorageAccountOfUserSpecifiedSubscription = $userSubscription.CurrentStorageAccountName
        }        
    }

    Write-VerboseWithTime 'Backup-Subscription: Fin'
}


<#
.SYNOPSIS
Restaura el estado "actual" en la suscripción de Microsoft Azure que se guardó en la variable $Script:originalSubscription del ámbito de script.

.DESCRIPTION
La función Restore-Subscription convierte la suscripción guardada en la variable $Script:originalSubscription en la suscripción actual (de nuevo). Si la suscripción original tiene una cuenta de almacenamiento, esta función la convierte en la cuenta de almacenamiento actual de la suscripción actual. La función restaura la suscripción solo si hay una variable $SubscriptionName que no es null en el entorno. De lo contrario, termina. Si $SubscriptionName contiene un valor pero $Script:originalSubscription es $null, Restore-Subscription usa el cmdlet Select-AzureSubscription para borrar las opciones Actual y Predeterminada de las suscripciones de Microsoft Azure PowerShell. Esta función no tiene parámetros; toma los datos de entrada y no devuelve nada (void). Puede usar -Verbose para escribir mensajes en el flujo detallado Verbose.

.INPUTS
Ninguno

.OUTPUTS
Ninguno

.EXAMPLE
PS C:\> Restore-Subscription
PS C:\>

.EXAMPLE
PS C:\> Restore-Subscription -Verbose
VERBOSE: Restore-Subscription: Start
VERBOSE: Restore-Subscription: End
#>
function Restore-Subscription
{
    [CmdletBinding()]
    param()

    Write-VerboseWithTime 'Restore-Subscription: Inicio'

    if ($Script:originalCurrentSubscription)
    {
        if ($Script:originalCurrentStorageAccount)
        {
            Set-AzureSubscription `
                -SubscriptionName $Script:originalCurrentSubscription.SubscriptionName `
                -CurrentStorageAccountName $Script:originalCurrentStorageAccount
        }

        Select-AzureSubscription -SubscriptionName $Script:originalCurrentSubscription.SubscriptionName
    }
    else 
    {
        Select-AzureSubscription -NoCurrent
        Select-AzureSubscription -NoDefault
    }
    
    if ($Script:userSpecifiedSubscription -and $Script:originalStorageAccountOfUserSpecifiedSubscription)
    {
        Set-AzureSubscription `
            -SubscriptionName $Script:userSpecifiedSubscription `
            -CurrentStorageAccountName $Script:originalStorageAccountOfUserSpecifiedSubscription
    }

    Write-VerboseWithTime 'Restore-Subscription: Fin'
}

<#
.SYNOPSIS
Busca una cuenta de almacenamiento de Microsoft Azure denominada "devtest*" en la suscripción actual.

.DESCRIPTION
La función Get-AzureVMStorage devuelve el nombre de la primera cuenta de almacenamiento con el patrón de nombre "devtest*" (no distingue mayúsculas de minúsculas) de la ubicación o grupo de afinidad especificados. Si la cuenta de almacenamiento "devtest*" no coincide con la ubicación o grupo de afinidad, la función la omite. Debe especificar una ubicación o un grupo de afinidad.

.PARAMETER  Location
Especifica la ubicación de la cuenta de almacenamiento. Los valores válidos son las ubicaciones de Microsoft Azure, por ejemplo, "Oeste de EE. UU.". Puede especificar una ubicación o un grupo de afinidad, pero no ambos.

.PARAMETER  AffinityGroup
Especifica el grupo de afinidad de la cuenta de almacenamiento. Puede especificar una ubicación o un grupo de afinidad, pero no ambos.

.INPUTS
Ninguno. No puede canalizar datos de entrada a esta función.

.OUTPUTS
System.String

.EXAMPLE
PS C:\> Get-AzureVMStorage -Location "East US"
devtest3-fabricam

.EXAMPLE
PS C:\> Get-AzureVMStorage -AffinityGroup Finance
PS C:\>

.EXAMPLE\
PS C:\> Get-AzureVMStorage -AffinityGroup Finance -Verbose
VERBOSE: Get-AzureVMStorage: Start
VERBOSE: Get-AzureVMStorage: End

.LINK
Get-AzureStorageAccount
#>
function Get-AzureVMStorage
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true, ParameterSetName = 'Location')]
        [String]
        $Location,

        [Parameter(Mandatory = $true, ParameterSetName = 'AffinityGroup')]
        [String]
        $AffinityGroup
    )

    Write-VerboseWithTime 'Get-AzureVMStorage: Inicio'

    $storages = @(Get-AzureStorageAccount -ErrorAction SilentlyContinue)
    $storageName = $null

    foreach ($storage in $storages)
    {
        # Obtenga la primera cuenta de almacenamiento cuyo nombre empiece por "devtest"
        if ($storage.Label -like 'devtest*')
        {
            if ($storage.AffinityGroup -eq $AffinityGroup -or $storage.Location -eq $Location)
            {
                $storageName = $storage.Label

                    Write-HostWithTime ('Get-AzureVMStorage: Cuenta de almacenamiento devtest encontrada ' + $storageName)
                    $storage | Out-String | Write-VerboseWithTime
                break
            }
        }
    }

    Write-VerboseWithTime 'Get-AzureVMStorage: Fin'
    return $storageName
}


<#
.SYNOPSIS
Crea una nueva cuenta de almacenamiento de Microsoft Azure con un nombre único que comienza por "devtest".

.DESCRIPTION
La función Add-AzureVMStorage crea una nueva cuenta de almacenamiento de Microsoft Azure en la suscripción actual. El nombre de la cuenta comienza por "devtest" seguido de una cadena alfanumérica única. La función devuelve el nombre de la nueva cuenta de almacenamiento. Debe especificar una ubicación o un grupo de afinidad para la nueva cuenta de almacenamiento.

.PARAMETER  Location
Especifica la ubicación de la cuenta de almacenamiento. Los valores válidos son las ubicaciones de Microsoft Azure, por ejemplo, "Oeste de EE. UU.". Puede especificar una ubicación o un grupo de afinidad, pero no ambos.

.PARAMETER  AffinityGroup
Especifica el grupo de afinidad de la cuenta de almacenamiento. Puede especificar una ubicación o un grupo de afinidad, pero no ambos.

.INPUTS
Ninguno. No puede canalizar datos de entrada a esta función.

.OUTPUTS
System.String. La cadena es el nombre de la nueva cuenta de almacenamiento

.EXAMPLE
PS C:\> Add-AzureVMStorage -Location "East Asia"
devtestd6b45e23a6dd4bdab

.EXAMPLE
PS C:\> Add-AzureVMStorage -AffinityGroup Finance
devtestd6b45e23a6dd4bdab

.EXAMPLE
PS C:\> Add-AzureVMStorage -AffinityGroup Finance -Verbose
VERBOSE: Add-AzureVMStorage: Start
VERBOSE: Add-AzureVMStorage: Created new storage acccount devtestd6b45e23a6dd4bdab"
VERBOSE: Add-AzureVMStorage: End
devtestd6b45e23a6dd4bdab

.LINK
New-AzureStorageAccount
#>
function Add-AzureVMStorage
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true, ParameterSetName = 'Location')]
        [String]
        $Location,

        [Parameter(Mandatory = $true, ParameterSetName = 'AffinityGroup')]
        [String]
        $AffinityGroup
    )

    Write-VerboseWithTime 'Add-AzureVMStorage: Inicio'

    # Cree un nombre único anexando parte de un GUID a "devtest"
    $name = 'devtest'
    $suffix = [guid]::NewGuid().ToString('N').Substring(0,24 - $name.Length)
    $name = $name + $suffix

    # Cree una nueva cuenta de almacenamiento de Microsoft Azure con una ubicación o grupo de afinidad
    if ($PSCmdlet.ParameterSetName -eq 'Location')
    {
        New-AzureStorageAccount -StorageAccountName $name -Location $Location | Out-Null
    }
    else
    {
        New-AzureStorageAccount -StorageAccountName $name -AffinityGroup $AffinityGroup | Out-Null
    }

    Write-HostWithTime ("Add-AzureVMStorage: Se creó la nueva cuenta de almacenamiento $name")
    Write-VerboseWithTime 'Add-AzureVMStorage: Fin'
    return $name
}


<#
.SYNOPSIS
Valida el archivo de configuración y devuelve una tabla hash con los valores del archivo de configuración.

.DESCRIPTION
La función Read-ConfigFile valida el archivo de configuración JSON y devuelve una tabla hash de valores seleccionados.
-- Empieza convirtiendo al archivo JSON en un objeto PSCustomObject.
La tabla hash de servicio en la nube tiene las claves siguientes:
-- webdeployparameters : Opcional. Puede ser $null o estar vacío.
-- Databases: Bases de datos SQL

.PARAMETER  ConfigurationFile
Especifica la ruta de acceso y el nombre del archivo de configuración JSON del proyecto web. Visual Studio genera automáticamente el archivo de configuración JSON cuando se crea un proyecto web y se guarda en la carpeta PublishScripts de la solución.

.PARAMETER HasWebDeployPackage
Indica que hay un archivo ZIP de paquete de Web Deploy para la aplicación web. Para especificar un valor de $true, use -HasWebDeployPackage o HasWebDeployPackage:$true. Para especificar un valor de false, use HasWebDeployPackage:$false. Este parámetro es obligatorio.

.INPUTS
Ninguno. No puede canalizar datos de entrada a esta función.

.OUTPUTS
System.Collections.Hashtable

.EXAMPLE
PS C:\> Read-ConfigFile -ConfigurationFile <path> -HasWebDeployPackage


Name                           Value                                                                                                                                                                     
----                           -----                                                                                                                                                                     
databases                      {@{connectionStringName=; databaseName=; serverName=; user=; password=}}                                                                                                  
cloudService                   @{name="contoso"; affinityGroup="contosoEast"; location=; virtualNetwork=; subnet=; availabilitySet=; virtualMachine=}                                                      
webDeployParameters            @{iisWebApplicationName="Default Web Site"} 
#>
function Read-ConfigFile
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateScript({Test-Path $_ -PathType Leaf})]
        [String]
        $ConfigurationFile,

        [Parameter(Mandatory = $true)]
        [Switch]
        $HasWebDeployPackage	    
    )

    Write-VerboseWithTime 'Read-ConfigFile: Inicio'

    # Obtenga el contenido del archivo JSON (-raw omite los saltos de línea) y conviértalo en un objeto PSCustomObject
    $config = Get-Content $ConfigurationFile -Raw | ConvertFrom-Json

    if (!$config)
    {
        throw ('Read-ConfigFile: Error en ConvertFrom-Json: ' + $error[0])
    }

    # Determine si el objeto environmentSettings tiene propiedades 'cloudService' (independientemente del valor de las mismas)
    $hasCloudServiceProperty = Test-Member -Object $config.environmentSettings -Member 'cloudService'

    if (!$hasCloudServiceProperty)
    {
        throw 'Read-ConfigFile: El archivo de configuración no contiene una propiedad cloudService.'
    }

    # Cree una tabla hash a partir de los valores de PSCustomObject
    $returnObject = New-Object -TypeName Hashtable

        $returnObject.Add('cloudService', $config.environmentSettings.cloudService)
        if ($HasWebDeployPackage)
        {
            $returnObject.Add('webDeployParameters', $config.environmentSettings.webdeployParameters)
        }

    if (Test-Member -Object $config.environmentSettings -Member 'databases')
    {
        $returnObject.Add('databases', $config.environmentSettings.databases)
    }

    Write-VerboseWithTime 'Read-ConfigFile: Fin'

    return $returnObject
}

<#
.SYNOPSIS
Agrega nuevos extremos de entrada a una máquina virtual y devuelve la máquina virtual con el nuevo extremo.

.DESCRIPTION
La función Add-AzureVMEndpoints agrega nuevos extremos de entrada a una máquina virtual y devuelve la máquina virtual con los nuevos extremos. La función llama al cmdlet Add-AzureEndpoint (módulo de Azure).

.PARAMETER  VM
Especifica el objeto de máquina virtual. Escriba un objeto de máquina virtual, por ejemplo, el tipo que devuelven los cmdlets New-AzureVM o Get-AzureVM. Puede canalizar objetos de Get-AzureVM a Add-AzureVMEndpoints.

.PARAMETER  Endpoints
Especifica una matriz de extremos que se va a agregar a la máquina virtual. Normalmente, estos extremos tienen como origen el archivo de configuración JSON que Visual Studio genera para los proyectos web. Use la función Read-ConfigFile de este módulo para convertir el archivo en una tabla hash. Los extremos son una propiedad de la clave cloudservice de la tabla hash ($<hashtable>.cloudservice.virtualmachine.endpoints). Por ejemplo,
PS C:\> $config.cloudservice.virtualmachine.endpoints
name      protocol publicport privateport
----      -------- ---------- -----------
http      tcp      80         80
https     tcp      443        443
WebDeploy tcp      8172       8172

.INPUTS
Microsoft.WindowsAzure.Commands.ServiceManagement.Model.IPersistentVM

.OUTPUTS
Microsoft.WindowsAzure.Commands.ServiceManagement.Model.IPersistentVM

.EXAMPLE
Get-AzureVM

.EXAMPLE

.LINK
Get-AzureVM

.LINK
Add-AzureEndpoint
#>
function Add-AzureVMEndpoints
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [Microsoft.WindowsAzure.Commands.ServiceManagement.Model.PersistentVM]
        $VM,

        [Parameter(Mandatory = $true)]
        [PSCustomObject[]]
        $Endpoints
    )

    Write-VerboseWithTime 'Add-AzureVMEndpoints: Inicio'

    # Agregue cada uno de los extremos del archivo JSON a la máquina virtual
    $Endpoints | ForEach-Object `
    {
        $_ | Out-String | Write-VerboseWithTime
        Add-AzureEndpoint -VM $VM -Name $_.name -Protocol $_.protocol -LocalPort $_.privateport -PublicPort $_.publicport | Out-Null
    }

    Write-VerboseWithTime 'Add-AzureVMEndpoints: Fin'
    return $VM
}

<#
.SYNOPSIS
Crea todos los elementos de una nueva máquina virtual en una suscripción de Microsoft Azure.

.DESCRIPTION
Esta función crea una máquina virtual (VM) de Microsoft Azure y devuelve la dirección URL de la VM implementada. La función configura los requisitos previos y llama después al cmdlet New-AzureVM (módulo de Azure) para crear una nueva máquina virtual. 
-- Llama al cmdlet New-AzureVMConfig (módulo de Azure) para obtener un objeto de configuración de máquina virtual. 
-- Si se incluye el parámetro Subnet para agregar la máquina virtual a una subred de Azure, llama a Set-AzureSubnet para establecer la lista de subredes de la máquina virtual. 
-- Llama a Add-AzureProvisioningConfig (módulo de Azure) para agregar elementos a la configuración de máquina virtual. Crea una configuración de aprovisionamiento de Windows independiente (-Windows) con una cuenta de administrador y una contraseña. 
-- Llama a la función Add-AzureVMEndpoints de este módulo para agregar los extremos especificados mediante el parámetro Endpoints. Esta función toma un objeto de máquina virtual y devuelve un objeto de máquina virtual con los extremos agregados. 
-- Llama al cmdlet Add-AzureVM para crear una nueva máquina virtual de Microsoft Azure y devuelve la nueva máquina virtual. Los valores de los parámetros de la función se suelen tomar del archivo de configuración JSON que Visual Studio genera para los proyectos web integrados en Microsoft Azure. La función Read-ConfigFile de este módulo convierte el archivo JSON en una tabla hash. Guarde la clave cloudservice de la tabla hash en una variable (por ejemplo, PSCustomObject) y use las propiedades del objeto personalizado como valores de parámetro.

.PARAMETER  VMName
Especifica un nombre para la nueva máquina virtual. El nombre de máquina virtual debe ser único en el servicio en la nube. Este parámetro es obligatorio.

.PARAMETER  VMSize
Especifica el tamaño de la máquina virtual. Los valores válidos son "ExtraSmall", "Small", "Medium", "Large", "ExtraLarge", "A5", "A6", y "A7". Este valor se envía como valor del parámetro InstanceSize de New-AzureVMConfig. Este parámetro es obligatorio. 

.PARAMETER  ServiceName
Especifica un nombre de un servicio de Microsoft Azure nuevo o existente. Este valor se envía al parámetro ServiceName del cmdlet New-AzureVM, que agrega la nueva máquina virtual al servicio de Microsoft Azure existente o, si se especifica la ubicación o grupo de afinidad, crea una nueva máquina virtual y un nuevo servicio en la suscripción actual. Este parámetro es obligatorio. 

.PARAMETER  ImageName
Especifica el nombre de la imagen de máquina virtual que se va a utilizar en el disco del sistema operativo. Este parámetro se envía como valor del parámetro ImageName del cmdlet New-AzureVMConfig. Este parámetro es obligatorio. 

.PARAMETER  UserName
Especifica un nombre de usuario de administrador. Este nombre se envía como valor del parámetro AdminUserName de Add-AzureProvisioningConfig. Este parámetro es obligatorio.

.PARAMETER  UserPassword
Especifica una contraseña para la cuenta de usuario de administrador. Esta contraseña se envía como valor del parámetro Password de Add-AzureProvisioningConfig. Este parámetro es obligatorio.

.PARAMETER  Endpoints
Especifica una matriz de extremos que se va a agregar a la máquina virtual. Este valor se envía a la función Add-AzureVMEndpoints que el módulo exporta. Este parámetro es opcional. Normalmente, estos extremos tienen como origen el archivo de configuración JSON que Visual Studio genera para los proyectos web. Use la función Read-ConfigFile de este módulo para convertir el archivo en una tabla hash. Los extremos son una propiedad de la clave cloudService de la tabla hash ($<hashtable>.cloudservice.virtualmachine.endpoints). 

.PARAMETER  AvailabilitySetName
Especifica el nombre de un conjunto de disponibilidad para la nueva máquina virtual. Cuando se sitúan varias máquinas virtuales en un conjunto de disponibilidad, Microsoft Azure intenta mantener estas máquinas virtuales en hosts diferentes para mejorar la continuidad del servicio si se produce un error en uno de los hosts. Este parámetro es opcional. 

.PARAMETER  VNetName
Especifica el nombre de red virtual donde se ha implementado la nueva máquina virtual. Este valor se envía al parámetro VNetName del cmdlet Add-AzureVM. Este parámetro es opcional. 

.PARAMETER  Location
Especifica una ubicación para la nueva máquina virtual. Los valores válidos son las ubicaciones de Microsoft Azure, por ejemplo, "Oeste de EE. UU.". El valor predeterminado es la ubicación de la suscripción. Este parámetro es opcional. 

.PARAMETER  AffinityGroup
Especifica un grupo de afinidad para la nueva máquina virtual. Un grupo de afinidad es un grupo de recursos relacionados. Cuando se especifica un grupo de afinidad, Microsoft Azure intenta mantener los recursos del grupo juntos para mejorar la eficacia. 

.PARAMETER  Subnet
Especifica la subred de la configuración de la nueva máquina virtual. Este valor se envía al cmdlet Set-AzureSubnet (módulo de Azure), que toma una máquina virtual y una matriz de nombres de subredes y devuelve una máquina virtual con las subredes en su configuración.

.PARAMETER EnableWebDeployExtension
Prepara la máquina virtual para su implementación. Prepara la máquina virtual para su implementación. Este parámetro es opcional. Si no se especifica, la máquina virtual se crea, pero no se implementa. El valor de este parámetro se incluye en el archivo de configuración JSON que Visual Studio genera para los servicios en la nube.

.PARAMETER VMImage
Especifica que ImageName es el nombre de una VMImage y no una OSImage. Este parámetro es opcional. Si no se especifica, ImageName se tratará como una OSImage. El valor de este parámetro se incluye en el archivo de configuración JSON que Visual Studio genera para las máquinas virtuales.

.PARAMETER GeneralizedImage
En el caso de una VMImage, especifica si el estado de SO es generalizado. Este parámetro es opcional. Si no se especifica, el script se comporta como lo haría si fuera una OSImage especializada. Este parámetro se omitirá en el caso de las OSImages. El valor de este parámetro se incluye en el archivo de configuración JSON que Visual Studio genera para las máquinas virtuales.

.INPUTS
Ninguno. Esta función no toma datos de entrada de la canalización.

.OUTPUTS
System.Url

.EXAMPLE
 Este comando llama a la función Add-AzureVM. Muchos de los valores de parámetro proceden de un objeto $CloudServiceConfiguration. Este objeto PSCustomObject es la clave cloudservice y los valores de la tabla hash que la función Read-ConfigFile devuelve. El origen es el archivo de configuración JSON que Visual Studio genera para los proyectos web.

PS C:\> $config = Read-Configfile <name>.json
PS C:\> $CloudServiceConfiguration = $config.cloudservice

PS C:\> Add-AzureVM `
-UserName $userName `
-UserPassword  $userPassword `
-ImageName $CloudServiceConfiguration.virtualmachine.vhdImage `
-VMName $CloudServiceConfiguration.virtualmachine.name `
-VMSize $CloudServiceConfiguration.virtualmachine.size`
-Endpoints $CloudServiceConfiguration.virtualmachine.endpoints `
-ServiceName $serviceName `
-Location $CloudServiceConfiguration.location `
-AvailabilitySetName $CloudServiceConfiguration.availabilitySet `
-VNetName $CloudServiceConfiguration.virtualNetwork `
-Subnet $CloudServiceConfiguration.subnet `
-AffinityGroup $CloudServiceConfiguration.affinityGroup `
-EnableWebDeployExtension

http://contoso.cloudapp.net

.EXAMPLE
PS C:\> $endpoints = [PSCustomObject]@{name="http";protocol="tcp";publicport=80;privateport=80}, `
                        [PSCustomObject]@{name="https";protocol="tcp";publicport=443;privateport=443},`
                        [PSCustomObject]@{name="WebDeploy";protocol="tcp";publicport=8172;privateport=8172}
PS C:\> Add-AzureVM `
-UserName admin01 `
-UserPassword "password" `
-ImageName bd507d3a70934695bc2128e3e5a255ba__RightImage-Windows-2012-x64-v13.4.12.2 `
-VMName DevTestVM123 `
-VMSize Small `
-Endpoints $endpoints `
-ServiceName DevTestVM1234 `
-Location "West US"

.LINK
New-AzureVMConfig

.LINK
Set-AzureSubnet

.LINK
Add-AzureProvisioningConfig

.LINK
Get-AzureDeployment
#>
function Add-AzureVM
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [String]
        $VMName,

        [Parameter(Mandatory = $true)]
        [String]
        $VMSize,

        [Parameter(Mandatory = $true)]
        [String]
        $ServiceName,

        [Parameter(Mandatory = $true)]
        [String]
        $ImageName,

        [Parameter(Mandatory = $false)]
        [String]
        $UserName,

        [Parameter(Mandatory = $false)]
        [String]
        $UserPassword,

        [Parameter(Mandatory = $false)]
        [AllowNull()]
        [Object[]]
        $Endpoints,

        [Parameter(Mandatory = $false)]
        [AllowEmptyString()]
        [String]
        $AvailabilitySetName,

        [Parameter(Mandatory = $false)]
        [AllowEmptyString()]
        [String]
        $VNetName,

        [Parameter(Mandatory = $false)]
        [AllowEmptyString()]
        [String]
        $Location,

        [Parameter(Mandatory = $false)]
        [AllowEmptyString()]
        [String]
        $AffinityGroup,

        [Parameter(Mandatory = $false)]
        [AllowEmptyString()]
        [String]
        $Subnet,

        [Parameter(Mandatory = $false)]
        [Switch]
        $EnableWebDeployExtension,

        [Parameter(Mandatory=$false)]
        [Switch]
        $VMImage,

        [Parameter(Mandatory=$false)]
        [Switch]
        $GeneralizedImage
    )

    Write-VerboseWithTime 'Add-AzureVM: Inicio'

	if ($VMImage)
	{
		$specializedImage = !$GeneralizedImage;
	}
	else
	{
		$specializedImage = $false;
	}

    # Cree un nuevo objeto de configuración de máquina virtual de Microsoft Azure.
    if ($AvailabilitySetName)
    {
        $vm = New-AzureVMConfig -Name $VMName -InstanceSize $VMSize -ImageName $ImageName -AvailabilitySetName $AvailabilitySetName
    }
    else
    {
        $vm = New-AzureVMConfig -Name $VMName -InstanceSize $VMSize -ImageName $ImageName
    }

    if (!$vm)
    {
        throw 'Add-AzureVM: No se pudo crear la configuración de máquina virtual de Azure.'
    }

    if ($Subnet)
    {
        # Defina la lista de subredes en la configuración de máquina virtual.
        $subnetResult = Set-AzureSubnet -VM $vm -SubnetNames $Subnet

        if (!$subnetResult)
        {
            throw ('Add-AzureVM: No se pudo establecer la subred ' + $Subnet)
        }
    }

    if (!$specializedImage)
    {
	    # Agregue datos de configuración a las opciones de configuración de la máquina virtual
        $vm = Add-AzureProvisioningConfig -VM $vm -Windows -Password $UserPassword -AdminUserName $UserName -NoRDPEndpoint -NoWinRMEndpoint

        if (!$vm)
		{
			throw ('Add-AzureVM: No se pudo crear la configuración de aprovisionamiento.')
		}
    }

    # Agregue extremos de entrada a la máquina virtual
    if ($Endpoints -and $Endpoints.Count -gt 0)
    {
        $vm = Add-AzureVMEndpoints -Endpoints $Endpoints -VM $vm
    }

    if (!$vm)
    {
        throw ('Add-AzureVM: No se pudieron crear los extremos.')
    }

    if ($EnableWebDeployExtension)
    {
        Write-VerboseWithTime 'Add-AzureVM: Agregue la extensión webdeploy'

        Write-VerboseWithTime 'Para ver la licencia de WebDeploy, visite http://go.microsoft.com/fwlink/?LinkID=389744. '

        $vm = Set-AzureVMExtension `
            -VM $vm `
            -ExtensionName WebDeployForVSDevTest `
            -Publisher 'Microsoft.VisualStudio.WindowsAzure.DevTest' `
            -Version '1.*' 

        if (!$vm)
        {
            throw ('Add-AzureVM: No se pudo agregar la extensión webdeploy.')
        }
    }

    # Cree una tabla hash de parámetros para utilizar el empaquetamiento
    $param = New-Object -TypeName Hashtable
    if ($VNetName)
    {
        $param.Add('VNetName', $VNetName)
    }

    # VMImages no admite ubicaciones por el momento. La nueva VM se creará en la misma cuenta de almacenamiento (ubicación) en la que está la imagen
    if (!$VMImage -and $Location)
    {
		$param.Add('Location', $Location)
    }

    if ($AffinityGroup)
    {
        $param.Add('AffinityGroup', $AffinityGroup)
    }

    $param.Add('ServiceName', $ServiceName)
    $param.Add('VMs', $vm)
    $param.Add('WaitForBoot', $true)

    $param | Out-String | Write-VerboseWithTime

    New-AzureVM @param | Out-Null

    Write-HostWithTime ('Add-AzureVM: Se creó la máquina virtual ' + $VMName)

    $url = [System.Uri](Get-AzureDeployment -ServiceName $ServiceName).Url

    if (!$url)
    {
        throw 'Add-AzureVM: No se encuentra la dirección URL de la máquina virtual.'
    }

    Write-HostWithTime ('Add-AzureVM: Publique la dirección URL https://' + $url.Host + ':' + $WebDeployPort + '/msdeploy.axd')

    Write-VerboseWithTime 'Add-AzureVM: Fin'

    return $url.AbsoluteUri
}


<#
.SYNOPSIS
Obtiene la máquina virtual de Microsoft Azure especificada.

.DESCRIPTION
La función Find-AzureVM obtiene una máquina virtual (VM) de Microsoft Azure basándose en el nombre del servicio y el nombre de máquina virtual. Esta función llama al cmdlet Test-AzureName (módulo de Azure) para comprobar que el nombre del servicio existe en Microsoft Azure. Si es así, la función llama al cmdlet Get-AzureVM para obtener la máquina virtual. Esta función devuelve una tabla hash con las claves vm y foundService.
-- FoundService: $True si Test-AzureName encuentra el servicio. En caso contrario, $False
-- VM: Contiene el objeto de máquina virtual cuando FoundService es true y Get-AzureVM devuelve el objeto de máquina virtual.

.PARAMETER  ServiceName
Nombre del servicio de Microsoft Azure existente. Este parámetro es obligatorio.

.PARAMETER  VMName
Nombre de una máquina virtual del servicio. Este parámetro es obligatorio.

.INPUTS
Ninguno. No puede canalizar datos de entrada a esta función.

.OUTPUTS
System.Collections.Hashtable

.EXAMPLE
PS C:\> Find-AzureVM -Service Contoso -Name ContosoVM2

Name                           Value
----                           -----
foundService                   True

DeploymentName        : Contoso
Name                  : ContosoVM2
Label                 :
VM                    : Microsoft.WindowsAzure.Commands.ServiceManagement.Model.PersistentVM
InstanceStatus        : ReadyRole
IpAddress             : 100.71.114.118
InstanceStateDetails  :
PowerState            : Started
InstanceErrorCode     :
InstanceFaultDomain   : 0
InstanceName          : ContosoVM2
InstanceUpgradeDomain : 0
InstanceSize          : Small
AvailabilitySetName   :
DNSName               : http://contoso.cloudapp.net/
ServiceName           : Contoso
OperationDescription  : Get-AzureVM
OperationId           : 3c38e933-9464-6876-aaaa-734990a882d6
OperationStatus       : Succeeded

.LINK
Get-AzureVM
#>
function Find-AzureVM
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [String]
        $ServiceName,

        [Parameter(Mandatory = $true)]
        [String]
        $VMName
    )

    Write-VerboseWithTime 'Find-AzureVM: Inicio'
    $foundService = $false
    $vm = $null

    if (Test-AzureName -Service -Name $ServiceName)
    {
        $foundService = $true
        $vm = Get-AzureVM -ServiceName $ServiceName -Name $VMName
        if ($vm)
        {
            Write-HostWithTime ('Find-AzureVM: Se encontró la máquina virtual existente ' + $vm.Name )
            $vm | Out-String | Write-VerboseWithTime
        }
    }

    Write-VerboseWithTime 'Find-AzureVM: Fin'
    return @{ VM = $vm; FoundService = $foundService }
}


<#
.SYNOPSIS
Busca o crea una máquina virtual en la suscripción que coincide con los valores del archivo de configuración JSON.

.DESCRIPTION
La función New-AzureVMEnvironment busca o crea una máquina virtual en la suscripción que coincide con los valores del archivo de configuración JSON que Visual Studio genera para los proyectos web. Toma un objeto PSCustomObject, que es la clave cloudservice de la tabla hash que Read-ConfigFile devuelve. Estos datos tienen su origen en el archivo de configuración JSON que Visual Studio genera. La función busca una máquina virtual (VM) en la suscripción con un nombre de servicio y un nombre de máquina virtual que coincidan con los valores del objeto personalizado CloudServiceConfiguration. Si no encuentra una VM que coincida, llama a la función Add-AzureVM de este módulo y usa los valores del objeto CloudServiceConfiguration para crearla. El entorno de la máquina virtual contiene una cuenta de almacenamiento cuyo nombre comienza por "devtest". Si la función no encuentra una cuenta de almacenamiento con ese patrón de nombre en la suscripción, la crea. La función devuelve una tabla hash con las claves VMUrl, userName y Password y valores de cadena.

.PARAMETER  CloudServiceConfiguration
Toma un objeto PSCustomObject que contiene la propiedad cloudservice de la tabla hash que la función Read-ConfigFile devuelve. Todos los valores se originan en el archivo de configuración JSON que Visual Studio genera para los proyectos web. Puede buscar este archivo en la carpeta PublishScripts de la solución. Este parámetro es obligatorio.
$config = Read-ConfigFile -ConfigurationFile <file>.json $cloudServiceConfiguration = $config.cloudService

.PARAMETER  VMPassword
Toma una tabla hash con las claves Name y Password, como por ejemplo: @{Name = "admin"; Password = "password"} Este parámetro es opcional. Si lo omite, los valores predeterminados son el nombre de usuario y la contraseña de la máquina virtual en el archivo de configuración JSON.

.INPUTS
PSCustomObject  System.Collections.Hashtable

.OUTPUTS
System.Collections.Hashtable

.EXAMPLE
$config = Read-ConfigFile -ConfigurationFile $<file>.json
$cloudSvcConfig = $config.cloudService
$namehash = @{name = "admin"; password = "password"}

New-AzureVMEnvironment `
    -CloudServiceConfiguration $cloudSvcConfig `
    -VMPassword $namehash

Name                           Value
----                           -----
UserName                       admin
VMUrl                          contoso.cloudnet.net
Password                       password

.LINK
Add-AzureVM

.LINK
New-AzureStorageAccount
#>
function New-AzureVMEnvironment
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [Object]
        $CloudServiceConfiguration,

        [Parameter(Mandatory = $false)]
        [AllowNull()]
        [Hashtable]
        $VMPassword
    )

    Write-VerboseWithTime ('New-AzureVMEnvironment: Inicio')

    if ($CloudServiceConfiguration.location -and $CloudServiceConfiguration.affinityGroup)
    {
        throw 'New-AzureVMEnvironment: Archivo de configuración incorrecto. Contiene location y affinityGroup a la vez'
    }

    if (!$CloudServiceConfiguration.location -and !$CloudServiceConfiguration.affinityGroup)
    {
        throw 'New-AzureVMEnvironment: Archivo de configuración incorrecto. No contiene location o affinityGroup'
    }

    # Si el objeto CloudServiceConfiguration tiene la propiedad 'name' (para el nombre de servicio) y esta propiedad contiene un valor, úselo. De lo contrario, utilice el nombre de máquina virtual del objeto CloudServiceConfiguration, que siempre contiene un valor.
    if ((Test-Member $CloudServiceConfiguration 'name') -and $CloudServiceConfiguration.name)
    {
        $serviceName = $CloudServiceConfiguration.name
    }
    else
    {
        $serviceName = $CloudServiceConfiguration.virtualMachine.name
    }

    if (!$VMPassword)
    {
        $userName = $CloudServiceConfiguration.virtualMachine.user
        $userPassword = $CloudServiceConfiguration.virtualMachine.password
    }
    else
    {
        $userName = $VMPassword.Name
        $userPassword = $VMPassword.Password
    }

    # Obtenga el nombre de máquina virtual del archivo JSON
    $findAzureVMResult = Find-AzureVM -ServiceName $serviceName -VMName $CloudServiceConfiguration.virtualMachine.name

    # Si no se encuentra ninguna máquina virtual con ese nombre en el servicio en la nube, cree una.
    if (!$findAzureVMResult.VM)
    {
        if(!$CloudServiceConfiguration.virtualMachine.isVMImage)
        {
            $storageAccountName = $null
            $imageInfo = Get-AzureVMImage -ImageName $CloudServiceConfiguration.virtualmachine.vhdimage 
            if ($imageInfo -and $imageInfo.Category -eq 'User')
            {
                $storageAccountName = ($imageInfo.MediaLink.Host -split '\.')[0]
            }

            if (!$storageAccountName)
            {
                if ($CloudServiceConfiguration.location)
                {
                    $storageAccountName = Get-AzureVMStorage -Location $CloudServiceConfiguration.location
                }
                else
                {
                    $storageAccountName = Get-AzureVMStorage -AffinityGroup $CloudServiceConfiguration.affinityGroup
                }
            }

             # Si no hay una cuenta de almacenamiento devtest*, cree una.
            if (!$storageAccountName)
            {
                if ($CloudServiceConfiguration.location)
                {
                    $storageAccountName = Add-AzureVMStorage -Location $CloudServiceConfiguration.location
                }
                else
                {
                    $storageAccountName = Add-AzureVMStorage -AffinityGroup $CloudServiceConfiguration.affinityGroup
                }
            }

            $currentSubscription = Get-AzureSubscription -Current

            if (!$currentSubscription)
            {
                throw 'New-AzureVMEnvironment: No se pudo obtener la suscripción actual de Azure.'
            }

            # Establezca la cuenta de almacenamiento devtest* como cuenta actual
            Set-AzureSubscription `
                -SubscriptionName $currentSubscription.SubscriptionName `
                -CurrentStorageAccountName $storageAccountName

            Write-VerboseWithTime ('New-AzureVMEnvironment: La cuenta de almacenamiento está establecida en ' + $storageAccountName)
        }

        $location = ''            
        if (!$findAzureVMResult.FoundService)
        {
            $location = $CloudServiceConfiguration.location
        }

        $endpoints = $null
        if (Test-Member -Object $CloudServiceConfiguration.virtualmachine -Member 'Endpoints')
        {
            $endpoints = $CloudServiceConfiguration.virtualmachine.endpoints
        }

        # Cree una máquina virtual con los valores del archivo JSON y los valores de parámetro
        $VMUrl = Add-AzureVM `
            -UserName $userName `
            -UserPassword $userPassword `
            -ImageName $CloudServiceConfiguration.virtualMachine.vhdImage `
            -VMName $CloudServiceConfiguration.virtualMachine.name `
            -VMSize $CloudServiceConfiguration.virtualMachine.size`
            -Endpoints $endpoints `
            -ServiceName $serviceName `
            -Location $location `
            -AvailabilitySetName $CloudServiceConfiguration.availabilitySet `
            -VNetName $CloudServiceConfiguration.virtualNetwork `
            -Subnet $CloudServiceConfiguration.subnet `
            -AffinityGroup $CloudServiceConfiguration.affinityGroup `
            -EnableWebDeployExtension:$CloudServiceConfiguration.virtualMachine.enableWebDeployExtension `
            -VMImage:$CloudServiceConfiguration.virtualMachine.isVMImage `
            -GeneralizedImage:$CloudServiceConfiguration.virtualMachine.isGeneralizedImage

        Write-VerboseWithTime ('New-AzureVMEnvironment: Fin')

        return @{ 
            VMUrl = $VMUrl; 
            UserName = $userName; 
            Password = $userPassword; 
            IsNewCreatedVM = $true; }
    }
    else
    {
        Write-VerboseWithTime ('New-AzureVMEnvironment: Se encontró una máquina virtual existente ' + $findAzureVMResult.VM.Name)
    }

    Write-VerboseWithTime ('New-AzureVMEnvironment: Fin')

    return @{ 
        VMUrl = $findAzureVMResult.VM.DNSName; 
        UserName = $userName; 
        Password = $userPassword; 
        IsNewCreatedVM = $false; }
}


<#
.SYNOPSIS
Devuelve un comando que va a ejecutar la herramienta MsDeploy.exe

.DESCRIPTION
La función Get-MSDeployCmd ensambla y devuelve un comando válido para ejecutar la Herramienta de implementación web (MSDeploy.exe). Busca la ruta de acceso correcta a la herramienta del equipo local en una clave del Registro. Esta función no tiene parámetros.

.INPUTS
Ninguno

.OUTPUTS
System.String

.EXAMPLE
PS C:\> Get-MSDeployCmd
C:\Program Files\IIS\Microsoft Web Deploy V3\MsDeploy.exe

.LINK
Get-MSDeployCmd

.LINK
Web Deploy Tool
http://technet.microsoft.com/en-us/library/dd568996(v=ws.10).aspx
#>
function Get-MSDeployCmd
{
    Write-VerboseWithTime 'Get-MSDeployCmd: Inicio'
    $regKey = 'HKLM:\SOFTWARE\Microsoft\IIS Extensions\MSDeploy'

    if (!(Test-Path $regKey))
    {
        throw ('Get-MSDeployCmd: No se encuentra ' + $regKey)
    }

    $versions = @(Get-ChildItem $regKey -ErrorAction SilentlyContinue)
    $lastestVersion =  $versions | Sort-Object -Property Name -Descending | Select-Object -First 1

    if ($lastestVersion)
    {
        $installPathKeys = 'InstallPath','InstallPath_x86'

        foreach ($installPathKey in $installPathKeys)
        {		    	
            $installPath = $lastestVersion.GetValue($installPathKey)

            if ($installPath)
            {
                $installPath = Join-Path $installPath -ChildPath 'MsDeploy.exe'

                if (Test-Path $installPath -PathType Leaf)
                {
                    $msdeployPath = $installPath
                    break
                }
            }
        }
    }

    Write-VerboseWithTime 'Get-MSDeployCmd: Fin'
    return $msdeployPath
}


<#
.SYNOPSIS
Devuelve $True cuando la dirección URL es absoluta y su esquema es https.

.DESCRIPTION
La función Test-HttpsUrl convierte la dirección URL de entrada en un objeto System.Uri. Devuelve $True cuando la dirección URL es absoluta (no relativa) y su esquema es https. Si es false o la cadena de entrada no puede convertirse en una dirección URL, la función devuelve $false.

.PARAMETER Url
Especifica la dirección URL que se va a probar. Escriba una cadena de dirección URL.

.INPUTS
NINGUNO.

.OUTPUTS
System.Boolean

.EXAMPLE
PS C:\>$profile.publishUrl
waws-prod-bay-001.publish.azurewebsites.windows.net:443

PS C:\>Test-HttpsUrl -Url 'waws-prod-bay-001.publish.azurewebsites.windows.net:443'
False

PS C:\>Test-HttpsUrl -Url 'https://waws-prod-bay-001.publish.azurewebsites.windows.net:443'
True
#>
function Test-HttpsUrl
{

    param
    (
        [Parameter(Mandatory = $true)]
        [String]
        $Url
    )

    # Si $uri no se puede convertir en un objeto System.Uri, Test-HttpsUrl devuelve $false
    $uri = $Url -as [System.Uri]

    return $uri.IsAbsoluteUri -and $uri.Scheme -eq 'https'
}


<#
.SYNOPSIS
Implementa un paquete web en Microsoft Azure.

.DESCRIPTION
La función Publish-WebPackage usa MsDeploy.exe y un archivo ZIP de paquete de implementación web para implementar recursos en un sitio web de Microsoft Azure. Esta función no genera ninguna salida. Si se produce un error en la llamada a MSDeploy.exe, la función produce una excepción. Para obtener una salida más detallada, use el parámetro común Verbose.

.PARAMETER  WebDeployPackage
Especifica la ruta de acceso y el nombre de un archivo ZIP de paquete de implementación web que Visual Studio genera. Este parámetro es obligatorio. Para crear un archivo ZIP de paquete de implementación web, vea el tema sobre la creación de paquetes de implementación web en Visual Studio que se encuentra en http://go.microsoft.com/fwlink/?LinkId=391353.

.PARAMETER PublishUrl
Especifica la dirección URL en la que se implementaron los recursos. La dirección URL debe usar el protocolo HTTPS e incluir el puerto. Este parámetro es obligatorio.

.PARAMETER SiteName
Especifica un nombre para el sitio web. Este parámetro es obligatorio.

.PARAMETER Username
Especifica el nombre de usuario del administrador del sitio web. Este parámetro es obligatorio.

.PARAMETER Password
Especifica una contraseña para el administrador del sitio web. Escriba la contraseña sin formato. No se permiten cadenas seguras. Este parámetro es obligatorio.

.PARAMETER AllowUntrusted
Permite conexiones SSL que no son de confianza con el extremo de Web Deploy. Este parámetro, que es opcional, se usa en la llamada a MSDeploy.exe.

.PARAMETER ConnectionString
Especifica una cadena de conexión para una base de datos SQL. Este parámetro toma una tabla hash con las claves Name y ConnectionString. El valor de Name es el nombre de la base de datos. El valor de ConnectionString es el valor de connectionStringName del archivo de configuración JSON.

.INPUTS
Ninguno. Esta función no toma datos de entrada de la canalización.

.OUTPUTS
Ninguno

.EXAMPLE
Publish-WebPackage -WebDeployPackage C:\Documents\Azure\ADWebApp.zip `
    -PublishUrl 'https://contoso.cloudapp.net:8172/msdeploy.axd' `
    -SiteName 'Sitio de prueba de Contoso' `
    -UserName 'admin01' `
    -Password 'password' `
    -AllowUntrusted:$False `
    -ConnectionString @{Name="TestDB";ConnectionString="DefaultConnection"}

.LINK
Publish-WebPackageToVM

.LINK
Web Deploy Command Line Reference (MSDeploy.exe)
http://go.microsoft.com/fwlink/?LinkId=391354
#>
function Publish-WebPackage
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateScript({Test-Path $_ -PathType Leaf})]
        [String]
        $WebDeployPackage,

        [Parameter(Mandatory = $true)]
        [ValidateScript({Test-HttpsUrl $_ })]
        [String]
        $PublishUrl,

        [Parameter(Mandatory = $true)]
        [String]
        $SiteName,

        [Parameter(Mandatory = $true)]
        [String]
        $UserName,

        [Parameter(Mandatory = $true)]
        [String]
        $Password,

        [Parameter(Mandatory = $false)]
        [Switch]
        $AllowUntrusted = $false,

        [Parameter(Mandatory = $true)]
        [Hashtable]
        $ConnectionString
    )

    Write-VerboseWithTime 'Publish-WebPackage: Inicio'

    $msdeployCmd = Get-MSDeployCmd

    if (!$msdeployCmd)
    {
        throw 'Publish-WebPackage: No se encuentra MsDeploy.exe.'
    }

    $WebDeployPackage = (Get-Item $WebDeployPackage).FullName

    $msdeployCmd =  '"' + $msdeployCmd + '"'
    $msdeployCmd += ' -verb:sync'
    $msdeployCmd += ' -Source:Package="{0}"'
    $msdeployCmd += ' -dest:auto,computername="{1}?site={2}",userName={3},password={4},authType=Basic'
    if ($AllowUntrusted)
    {
        $msdeployCmd += ' -allowUntrusted'
    }
    $msdeployCmd += ' -setParam:name="IIS Web Application Name",value="{2}"'

    foreach ($DBConnection in $ConnectionString.GetEnumerator())
    {
        $msdeployCmd += (' -setParam:name="{0}",value="{1}"' -f $DBConnection.Key, $DBConnection.Value)
    }

    $msdeployCmd = $msdeployCmd -f $WebDeployPackage, $PublishUrl, $SiteName, $UserName, $Password
    $msdeployCmdForVerboseMessage = $msdeployCmd -f $WebDeployPackage, $PublishUrl, $SiteName, $UserName, '********'

    Write-VerboseWithTime ('Publish-WebPackage: MsDeploy: ' + $msdeployCmdForVerboseMessage)

    $msdeployExecution = Start-Process cmd.exe -ArgumentList ('/C "' + $msdeployCmd + '" ') -WindowStyle Normal -Wait -PassThru

    if ($msdeployExecution.ExitCode -ne 0)
    {
         Write-VerboseWithTime ('Msdeploy.exe terminó con errores. ExitCode:' + $msdeployExecution.ExitCode)
    }

    Write-VerboseWithTime 'Publish-WebPackage: Fin'
    return ($msdeployExecution.ExitCode -eq 0)
}


<#
.SYNOPSIS
Implementa una máquina virtual en Microsoft Azure.

.DESCRIPTION
La función Publish-WebPackageToVM es una función de ayuda que comprueba los valores de parámetro y llama después a la función Publish-WebPackage.

.PARAMETER  VMDnsName
Especifica el nombre DNS de la máquina virtual de Microsoft Azure. Este parámetro es obligatorio.

.PARAMETER IisWebApplicationName
Especifica el nombre de una aplicación web de IIS para la máquina virtual. Este parámetro es obligatorio. Este es el nombre de la aplicación web de Visual Studio. Puede buscar el nombre en el atributo webDeployparameters del archivo de configuración JSON que genera Visual Studio.

.PARAMETER WebDeployPackage
Especifica la ruta de acceso y el nombre de un archivo ZIP de paquete de implementación web que Visual Studio genera. Este parámetro es obligatorio. Para crear un archivo ZIP de paquete de implementación web, vea el tema sobre la creación de paquetes de implementación web en Visual Studio que se encuentra en http://go.microsoft.com/fwlink/?LinkId=391353.

.PARAMETER Username
Especifica el nombre de usuario del administrador de la máquina virtual. Este parámetro es obligatorio.

.PARAMETER Password
Especifica una contraseña para el administrador de la máquina virtual. Escriba la contraseña sin formato. No se permiten cadenas seguras. Este parámetro es obligatorio.

.PARAMETER AllowUntrusted
Permite conexiones SSL que no son de confianza con el extremo de Web Deploy. Este parámetro, que es opcional, se usa en la llamada a MSDeploy.exe.

.PARAMETER ConnectionString
Especifica una cadena de conexión para una base de datos SQL. Este parámetro toma una tabla hash con las claves Name y ConnectionString. El valor de Name es el nombre de la base de datos. El valor de ConnectionString es el valor de connectionStringName del archivo de configuración JSON.

.INPUTS
Ninguno. Esta función no toma datos de entrada de la canalización.

.OUTPUTS
Ninguno.

.EXAMPLE
Publish-WebPackageToVM -VMDnsName contoso.cloudapp.net `
-IisWebApplicationName myTestWebApp `
-WebDeployPackage C:\Documents\Azure\ADWebApp.zip
-Username 'admin01' `
-Password 'password' `
-AllowUntrusted:$False `
-ConnectionString @{Name="TestDB";ConnectionString="DefaultConnection"}

.LINK
Publish-WebPackage
#>
function Publish-WebPackageToVM
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String]
        $VMDnsName,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String]
        $IisWebApplicationName,

        [Parameter(Mandatory = $true)]
        [ValidateScript({Test-Path $_ -PathType Leaf})]
        [String]
        $WebDeployPackage,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String]
        $UserName,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String]
        $UserPassword,

        [Parameter(Mandatory = $true)]
        [Bool]
        $AllowUntrusted,
        
        [Parameter(Mandatory = $true)]
        [Hashtable]
        $ConnectionString
    )
    Write-VerboseWithTime 'Publish-WebPackageToVM: Inicio'

    $VMDnsUrl = $VMDnsName -as [System.Uri]

    if (!$VMDnsUrl)
    {
        throw ('Publish-WebPackageToVM: Dirección URL no válida ' + $VMDnsUrl)
    }

    $publishUrl = 'https://{0}:{1}/msdeploy.axd' -f $VMDnsUrl.Host, $WebDeployPort

    $result = Publish-WebPackage `
        -WebDeployPackage $WebDeployPackage `
        -PublishUrl $publishUrl `
        -SiteName $IisWebApplicationName `
        -UserName $UserName `
        -Password $UserPassword `
        -AllowUntrusted:$AllowUntrusted `
        -ConnectionString $ConnectionString

    Write-VerboseWithTime 'Publish-WebPackageToVM: Fin'
    return $result
}


<#
.SYNOPSIS
Crea una cadena que permite conectarse a una base de datos SQL de Microsoft Azure.

.DESCRIPTION
La función Get-AzureSQLDatabaseConnectionString ensambla una cadena de conexión que se va a conectar a una base de datos SQL de Microsoft Azure.

.PARAMETER  DatabaseServerName
Especifica el nombre de un servidor de bases de datos existente en la suscripción de Microsoft Azure. Todas las bases de datos SQL de Microsoft Azure deben estar asociadas a un servidor de bases de datos SQL. Para obtener el nombre del servidor, use el cmdlet Get-AzureSqlDatabaseServer (módulo de Azure). Este parámetro es obligatorio.

.PARAMETER  DatabaseName
Especifica el nombre de la base de datos SQL. Puede ser una base de datos SQL existente o el nombre de una base de datos SQL nueva. Este parámetro es obligatorio.

.PARAMETER  Username
Especifica el nombre del administrador de bases de datos SQL. El nombre de usuario será $Username@DatabaseServerName. Este parámetro es obligatorio.

.PARAMETER  Password
Especifica una contraseña para el administrador de bases de datos SQL. Escriba la contraseña sin formato. No se permiten cadenas seguras. Este parámetro es obligatorio.

.INPUTS
Ninguno.

.OUTPUTS
System.String

.EXAMPLE
PS C:\> $ServerName = (Get-AzureSqlDatabaseServer).ServerName[0]
PS C:\> Get-AzureSQLDatabaseConnectionString -DatabaseServerName $ServerName `
        -DatabaseName 'testdb' -UserName 'admin'  -Password 'password'

Server=tcp:testserver.database.windows.net,1433;Database=testdb;User ID=admin@bebad12345;Password=password;Trusted_Connection=False;Encrypt=True;Connection Timeout=20;
#>
function Get-AzureSQLDatabaseConnectionString
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [String]
        $DatabaseServerName,

        [Parameter(Mandatory = $true)]
        [String]
        $DatabaseName,

        [Parameter(Mandatory = $true)]
        [String]
        $UserName,

        [Parameter(Mandatory = $true)]
        [String]
        $Password
    )

    return ('Server=tcp:{0}.database.windows.net,1433;Database={1};' +
           'User ID={2}@{0};' +
           'Password={3};' +
           'Trusted_Connection=False;' +
           'Encrypt=True;' +
           'Connection Timeout=20;') `
           -f $DatabaseServerName, $DatabaseName, $UserName, $Password
}


<#
.SYNOPSIS
Crea bases de datos SQL de Microsoft Azure a partir de los valores del archivo de configuración JSON que Visual Studio genera.

.DESCRIPTION
La función Add-AzureSQLDatabases toma la información de la sección de bases de datos del archivo JSON. Esta función, Add-AzureSQLDatabases (plural), llama a la función Add-AzureSQLDatabase (singular) de cada base de datos SQL del archivo JSON. Add-AzureSQLDatabase (singular) llama al cmdlet New-AzureSqlDatabase (módulo de Azure), que crea las bases de datos SQL. Esta función no devuelve un objeto de base de datos. Devuelve una tabla hash de los valores que se utilizaron para crear las bases de datos.

.PARAMETER DatabaseConfig
 Toma una matriz de PSCustomObjects que tiene su origen en el archivo JSON que la función Read-ConfigFile devuelve cuando el archivo JSON tiene una propiedad de sitio web. Incluye las propiedades de environmentSettings.databases. Puede canalizar la lista a esta función.
PS C:\> $config = Read-ConfigFile <name>.json
PS C:\> $DatabaseConfig = $config.databases| where {$_.connectionStringName}
PS C:\> $DatabaseConfig
connectionStringName: Default Connection
databasename : TestDB1
edition   :
size     : 1
collation  : SQL_Latin1_General_CP1_CI_AS
servertype  : New SQL Database Server
servername  : r040tvt2gx
user     : dbuser
password   : Test.123
location   : West US

.PARAMETER  DatabaseServerPassword
Especifica la contraseña para el administrador del servidor de bases de datos SQL. Escriba una tabla hash con las claves Name y Password. El valor de Name es el nombre del servidor de bases de datos SQL. El valor de Password es la contraseña de administrador. Por ejemplo: @Name = "TestDB1"; Password = "password" Este parámetro es opcional. Si lo omite o el nombre del servidor de bases de datos SQL no coincide con el valor de la propiedad serverName del objeto $DatabaseConfig, la función usa la propiedad Password del objeto $DatabaseConfig para la base de datos SQL en la cadena de conexión.

.PARAMETER CreateDatabase
Se asegura de que se pretende crear una base de datos. Este parámetro es opcional.

.INPUTS
System.Collections.Hashtable[]

.OUTPUTS
System.Collections.Hashtable

.EXAMPLE
PS C:\> $config = Read-ConfigFile <name>.json
PS C:\> $DatabaseConfig = $config.databases| where {$_.connectionStringName}
PS C:\> $DatabaseConfig | Add-AzureSQLDatabases

Name                           Value
----                           -----
ConnectionString               Server=tcp:testdb1.database.windows.net,1433;Database=testdb;User ID=admin@testdb1;Password=password;Trusted_Connection=False;Encrypt=True;Connection Timeout=20;
Name                           Default Connection
Type                           SQLAzure

.LINK
Get-AzureSQLDatabaseConnectionString

.LINK
Create-AzureSQLDatabase
#>
function Add-AzureSQLDatabases
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [PSCustomObject]
        $DatabaseConfig,

        [Parameter(Mandatory = $false)]
        [AllowNull()]
        [Hashtable[]]
        $DatabaseServerPassword,

        [Parameter(Mandatory = $false)]
        [Switch]
        $CreateDatabase = $false
    )

    begin
    {
        Write-VerboseWithTime 'Add-AzureSQLDatabases: Inicio'
    }
    process
    {
        Write-VerboseWithTime ('Add-AzureSQLDatabases: Creando ' + $DatabaseConfig.databaseName)

        if ($CreateDatabase)
        {
            # Cree una nueva base de datos SQL con los valores de DatabaseConfig (a menos que exista una)
            # Se suprimió la salida del comando.
            Add-AzureSQLDatabase -DatabaseConfig $DatabaseConfig | Out-Null
        }

        $serverPassword = $null
        if ($DatabaseServerPassword)
        {
            foreach ($credential in $DatabaseServerPassword)
            {
               if ($credential.Name -eq $DatabaseConfig.serverName)
               {
                   $serverPassword = $credential.password             
                   break
               }
            }               
        }

        if (!$serverPassword)
        {
            $serverPassword = $DatabaseConfig.password
        }

        return @{
            Name = $DatabaseConfig.connectionStringName;
            Type = 'SQLAzure';
            ConnectionString = Get-AzureSQLDatabaseConnectionString `
                -DatabaseServerName $DatabaseConfig.serverName `
                -DatabaseName $DatabaseConfig.databaseName `
                -UserName $DatabaseConfig.user `
                -Password $serverPassword }
    }
    end
    {
        Write-VerboseWithTime 'Add-AzureSQLDatabases: Fin'
    }
}


<#
.SYNOPSIS
Crea una nueva base de datos SQL de Microsoft Azure.

.DESCRIPTION
La función Add-AzureSQLDatabase crea una base de datos SQL de Microsoft Azure a partir de los datos del archivo de configuración JSON que Visual Studio genera y devuelve la nueva base de datos. Si la suscripción ya tiene una base de datos SQL con el nombre especificado en el servidor de bases de datos SQL indicado, la función devuelve la base de datos existente. Esta función llama al cmdlet New-AzureSqlDatabase (módulo de Azure), que es el que en realidad crea la base de datos SQL.

.PARAMETER DatabaseConfig
Toma un objeto PSCustomObject que tiene su origen en el archivo de configuración JSON que la función Read-ConfigFile devuelve cuando el archivo JSON tiene una propiedad de sitio web. Incluye las propiedades de environmentSettings.databases. No se puede canalizar el objeto a esta función. Visual Studio genera un archivo de configuración JSON para todos los proyectos web y lo guarda en la carpeta PublishScripts de la solución.

.INPUTS
Ninguno. Esta función no toma datos de entrada de la canalización

.OUTPUTS
Microsoft.WindowsAzure.Commands.SqlDatabase.Services.Server.Database

.EXAMPLE
PS C:\> $config = Read-ConfigFile <name>.json
PS C:\> $DatabaseConfig = $config.databases | where connectionStringName
PS C:\> $DatabaseConfig

connectionStringName    : Default Connection
databasename : TestDB1
edition      :
size         : 1
collation    : SQL_Latin1_General_CP1_CI_AS
servertype   : New SQL Database Server
servername   : r040tvt2gx
user         : dbuser
password     : Test.123
location     : West US

PS C:\> Add-AzureSQLDatabase -DatabaseConfig $DatabaseConfig

.LINK
Add-AzureSQLDatabases

.LINK
New-AzureSQLDatabase
#>
function Add-AzureSQLDatabase
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [Object]
        $DatabaseConfig
    )

    Write-VerboseWithTime 'Add-AzureSQLDatabase: Inicio'

    # Si el valor de parámetro no tiene la propiedad serverName o si la propiedad serverName no tiene ningún valor, se produce un error.
    if (-not (Test-Member $DatabaseConfig 'serverName') -or -not $DatabaseConfig.serverName)
    {
        throw 'Add-AzureSQLDatabase: Falta el valor serverName del servidor de bases de datos (obligatorio) en el valor de DatabaseConfig.'
    }

    # Si el valor de parámetro no tiene la propiedad databasename o si la propiedad databasename no tiene ningún valor, se produce un error.
    if (-not (Test-Member $DatabaseConfig 'databaseName') -or -not $DatabaseConfig.databaseName)
    {
        throw 'Add-AzureSQLDatabase: Falta el nombre de base de datos (obligatorio) en el valor de DatabaseConfig.'
    }

    $DbServer = $null

    if (Test-HttpsUrl $DatabaseConfig.serverName)
    {
        $absoluteDbServer = $DatabaseConfig.serverName -as [System.Uri]
        $subscription = Get-AzureSubscription -Current -ErrorAction SilentlyContinue

        if ($subscription -and $subscription.ServiceEndpoint -and $subscription.SubscriptionId)
        {
            $absoluteDbServerRegex = 'https:\/\/{0}\/{1}\/services\/sqlservers\/servers\/(.+)\.database\.windows\.net\/databases' -f `
                                     $subscription.serviceEndpoint.Host, $subscription.SubscriptionId

            if ($absoluteDbServer -match $absoluteDbServerRegex -and $Matches.Count -eq 2)
            {
                 $DbServer = $Matches[1]
            }
        }
    }

    if (!$DbServer)
    {
        $DbServer = $DatabaseConfig.serverName
    }

    $db = Get-AzureSqlDatabase -ServerName $DbServer -DatabaseName $DatabaseConfig.databaseName -ErrorAction SilentlyContinue

    if ($db)
    {
        Write-HostWithTime ('Create-AzureSQLDatabase: Se está usando la base de datos existente ' + $db.Name)
        $db | Out-String | Write-VerboseWithTime
    }
    else
    {
        $param = New-Object -TypeName Hashtable
        $param.Add('serverName', $DbServer)
        $param.Add('databaseName', $DatabaseConfig.databaseName)

        if ((Test-Member $DatabaseConfig 'size') -and $DatabaseConfig.size)
        {
            $param.Add('MaxSizeGB', $DatabaseConfig.size)
        }
        else
        {
            $param.Add('MaxSizeGB', 1)
        }

        # Si el objeto $DatabaseConfig tiene una propiedad de intercalación y no es null o está vacía
        if ((Test-Member $DatabaseConfig 'collation') -and $DatabaseConfig.collation)
        {
            $param.Add('Collation', $DatabaseConfig.collation)
        }

        # Si el objeto $DatabaseConfig tiene una propiedad de edición y no es null o está vacía
        if ((Test-Member $DatabaseConfig 'edition') -and $DatabaseConfig.edition)
        {
            $param.Add('Edition', $DatabaseConfig.edition)
        }

        # Escriba la tabla hash en el flujo detallado (Verbose)
        $param | Out-String | Write-VerboseWithTime
        # Llame a New-AzureSqlDatabase utilizando el empaquetamiento (suprima la salida)
        $db = New-AzureSqlDatabase @param
    }

    Write-VerboseWithTime 'Add-AzureSQLDatabase: Fin'
    return $db
}
