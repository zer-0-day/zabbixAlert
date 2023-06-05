#старница авторизации. Используя токен
$Global:timeout = 60
$baseurl = 'https://zabbix.office.partner-its.ru'
$params = @{
    body =  @{
        "jsonrpc"= "2.0"
        "method"= "user.login"
        "id"= 1
        auth = ""   
    } | ConvertTo-Json
    uri = "$baseurl/api_jsonrpc.php"
    headers = @{"Content-Type" = "application/json"}
    method = "Post"
}
$result = Invoke-WebRequest @params
#цикл проверки
while (1 -eq 1) {
#обращение к api триггеров 
$params.body = @{
    "jsonrpc"= "2.0"
    "method"= "trigger.get"
#параметры получаемых объектов
    "params" = @{
        state = "0"
        name = ""
        hostid = ""
        monitored = "True"
        active = "True"
        only_true = "True"
        min_severity = "5"
        expandComment = "True"
        expandDescription = "True"
        
    }
auth = ""
#($result.Content | ConvertFrom-Json).result
id = 2
} | ConvertTo-Json
$result = Invoke-WebRequest @params
$result = $result.Content 

#конвертирование json в PSObject
$userObject = ConvertFrom-Json -InputObject $result

#сортировка полученных объектов
$Global:problemList = ($userobject.result |Where-Object description |Select-Object description) -replace "{description=" , "" -replace "}" , "" -replace "@" , ""

#форма вывода сообщения об ошибке
Function ErrorMessageBox {
Add-Type -AssemblyName PresentationFramework
[void][System.Reflection.Assembly]::LoadWithPartialName('presentationframework')
[XML]$form = @"
<Window 
        xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        
        Title="Zabbix" Height="130" Width="348" Background="Black">
    <Grid Background="#FFD81B1B" Margin="-23,0,0,-6">
        <Grid.RowDefinitions>
            <RowDefinition Height="29*"/>
            <RowDefinition Height="27*"/>
        </Grid.RowDefinitions>
        <Grid.ColumnDefinitions>
            <ColumnDefinition Width="31*"/>
            <ColumnDefinition Width="0*"/>
            <ColumnDefinition Width="42*"/>
            <ColumnDefinition Width="298*"/>
            <ColumnDefinition Width="0*"/>
            <ColumnDefinition Width="0*"/>
        </Grid.ColumnDefinitions>
        <TextBlock HorizontalAlignment="Left" Margin="5,10,0,0" TextWrapping="Wrap" Text= '$problemList' VerticalAlignment="Top" Height="36" Width="312" RenderTransformOrigin="0.533,-0.867" Background="White" Grid.Column="2" Grid.ColumnSpan="2"/>
        <Button Name="Acept" Content="Принять" HorizontalAlignment="Left" Height="24" Margin="5,55,0,0" VerticalAlignment="Top" Width="73"  Grid.Column="2" Grid.RowSpan="2" Grid.ColumnSpan="2"/>
        <Button Name="Delay" Content="Отложить" HorizontalAlignment="Left" Height="24" Margin="204,55,0,0" VerticalAlignment="Top" Width="73"  Grid.Column="3" Grid.RowSpan="2"/>

    </Grid>
</Window>
"@
$NR = (New-Object System.Xml.XmlNodeReader $form)
$window = [Windows.Markup.XamlReader]::Load($NR)

#кнопка "Отложить" . Приостанавливает работу программы на 1 минуту 
$buttonDelay = $window.FindName("Delay") #Добавить всплывающее уведомление
$buttonDelay.add_click(
    {
    $window.Close()
    Start-Sleep -Seconds 60  
    }
)

#кнопка "Принять" приостанавливает работу программы на 1 час
$buttonAcept = $window.FindName("Acept")
$buttonAcept.add_click(
    {
        $window.Close
        Start-Sleep -Seconds 3600
    }

)
#инициализация формы с описанием проблемы
$window.ShowDialog()
}

# проверка содержимого $problemList
if ($problemList) {
# Звуковое оповещение            
    [console]::beep(440,500)
    [console]::beep(440,500)
   
#вызов функции ErrorMessageBox, вывод сообщения об ошибке  
ErrorMessageBox
Write-Host $problemList
}

#если проблем нет
if (!($problemList)){  
#изменение таймаута запросов к zabbix        
    $timeout = 15
}
Start-Sleep -Seconds $timeout
}

