Add-Type -AssemblyName PresentationFramework

[xml]$XAML = Get-Content -Path "MainWindow.xaml"
$Reader=(New-Object System.Xml.XmlNodeReader $XAML)
$MainWindow = [Windows.Markup.XamlReader]::Load($Reader)

#Création des variables pour tous les champs du XAML
$XAML.SelectNodes("//*[@*[contains(translate(name(.),'n','N'),'Name')]]")  | ForEach-Object { 
    New-Variable -Name $_.Name -Value $MainWindow.FindName($_.Name) -Force 
}

#**************************************
# Panneau utilisateur
#**************************************

# Gestion de l'exemple de texte dans le champ Hexa
$UserTab_HexaTextBox.Add_GotFocus({
    
    if ($UserTab_HexaTextBox.Text -eq 'ABC123') {
        $UserTab_HexaTextBox.Foreground = 'Black'
        $UserTab_HexaTextBox.Text = ''
    }
})

$UserTab_HexaTextBox.Add_LostFocus({
    if ($UserTab_HexaTextBox.Text -eq '') {
        $UserTab_HexaTextBox.Text = 'ABC123'
        $UserTab_HexaTextBox.Foreground = 'Darkgray'
    }
})

# Gestion du bouton de recherche
$UserTab_SearchButton.Add_Click({

    # Initialisation du résultat
    $UserTab_ResultComboBox.ItemsSource = $null

    If ($UserTab_HexaTextBox.Text -match '^[A-Z]{3}\d{3}$' -and $UserTab_NameTextBox.Text -eq '') { # Recherche avec uniquement l'hexagramme
        $results = @(Get-ADUser -filter "samaccountname -like '*$($UserTab_HexaTextBox.Text)*' " -Properties DistinguishedName, Enabled, LastLogonDate, MemberOf, Manager | 
            ForEach-Object { [PSCustomObject]@{
                DisplayName="$($_.Name) ($($_.SamAccountName))"
                SamAccountName=$_.SamAccountName
                DistinguishedName=$_.DistinguishedName
                Enabled=$_.Enabled
                LastLogonDate=$_.LastLogonDate
                MemberOf=$_.MemberOf
                Manager=$_.Manager
            }} | 
            Sort-Object -Property DisplayName)
        If ($results.Length -ne 0) {
            $UserTab_ResultComboBox.ItemsSource = $results
            $UserTab_ResultComboBox.DisplayMemberPath = 'DisplayName'
            $UserTab_ResultComboBox.SelectedIndex = 0
        } Else {
            $UserTab_ResultComboBox.ItemsSource = @([PSCustomObject]@{
                DisplayName="Aucun résultat"
                SamAccountName=""
                DistinguishedName=""
                Enabled=$false
                LastLogonDate=$null
                MemberOf=@()
            })
            $UserTab_ResultComboBox.DisplayMemberPath = 'DisplayName'
            $UserTab_ResultComboBox.SelectedIndex = 0
        }
    } elseif ($UserTab_HexaTextBox.Text -eq 'ABC123' -and $UserTab_NameTextBox.Text -ne '') { # Recherche avec uniquement le nom
        $results = @(Get-ADUser -filter "displayname -like '*$($UserTab_NameTextBox.Text)*'" -Properties DistinguishedName, Enabled, LastLogonDate, MemberOf | 
            ForEach-Object { [PSCustomObject]@{
                DisplayName="$($_.Name) ($($_.SamAccountName))"
                SamAccountName=$_.SamAccountName
                DistinguishedName=$_.DistinguishedName
                Enabled=$_.Enabled
                LastLogonDate=$_.LastLogonDate
                MemberOf=$_.MemberOf
            }} | 
            Sort-Object -Property DisplayName)
        If ($results.Length -ne 0) {
            $UserTab_ResultComboBox.ItemsSource = $results
            $UserTab_ResultComboBox.DisplayMemberPath = 'DisplayName'
            $UserTab_ResultComboBox.SelectedIndex = 0
        } Else {
            $UserTab_ResultComboBox.ItemsSource = @([PSCustomObject]@{
                DisplayName="Aucun résultat"
                SamAccountName=""
                DistinguishedName=""
                Enabled=$false
                LastLogonDate=$null
                MemberOf=@()
            })
            $UserTab_ResultComboBox.DisplayMemberPath = 'DisplayName'
            $UserTab_ResultComboBox.SelectedIndex = 0
        }
    } elseif ($UserTab_HexaTextBox.Text -match '^[A-Z]{3}\d{3}$' -and $UserTab_HexaTextBox.Text -ne 'ABC123' -and $UserTab_NameTextBox.Text -ne '') { # Recherche avec l'hexagramme et le nom
        $results = @(Get-ADUser -filter "samaccountname -like '*$($UserTab_HexaTextBox.Text)*' -and displayname -like '*$($UserTab_HexaTextBox.Text)*'" -Properties DistinguishedName, Enabled, LastLogonDate, MemberOf | 
            ForEach-Object { [PSCustomObject]@{
                DisplayName="$($_.Name) ($($_.SamAccountName))"
                SamAccountName=$_.SamAccountName
                DistinguishedName=$_.DistinguishedName
                Enabled=$_.Enabled
                LastLogonDate=$_.LastLogonDate
                MemberOf=$_.MemberOf
            }} | 
            Sort-Object -Property DisplayName)
        If ($results.Length -ne 0) {
            $UserTab_ResultComboBox.ItemsSource = $results
            $UserTab_ResultComboBox.DisplayMemberPath = 'DisplayName'
            $UserTab_ResultComboBox.SelectedIndex = 0
        } Else {
            $UserTab_ResultComboBox.ItemsSource = @([PSCustomObject]@{
                DisplayName="Aucun résultat"
                SamAccountName=""
                DistinguishedName=""
                Enabled=$false
                LastLogonDate=$null
                MemberOf=@()
            })
            $UserTab_ResultComboBox.DisplayMemberPath = 'DisplayName'
            $UserTab_ResultComboBox.SelectedIndex = 0
        }
    } else {
        $UserTab_ResultComboBox.ItemsSource = @([PSCustomObject]@{
            DisplayName="Aucun résultat"
            SamAccountName=""
            DistinguishedName=""
            Enabled=$false
            LastLogonDate=$null
            MemberOf=@()
        })
        $UserTab_ResultComboBox.DisplayMemberPath = 'DisplayName'
        $UserTab_ResultComboBox.SelectedIndex = 0
    }
})

# Affichage des données du champ d'utilisateur sélectionné dans les champs de la fenêtre
$UserTab_ResultComboBox.Add_SelectionChanged({
    if ($UserTab_ResultComboBox.SelectedItem -ne $null) {
        $selectedUser = $UserTab_ResultComboBox.SelectedItem
        $UserTab_SamAccountTextBox.Text = $selectedUser.SamAccountName
        $UserTab_DistinguishedNameListBox.ItemsSource = @($selectedUser.DistinguishedName)
        $UserTab_StatusTextBox.Text = if ($selectedUser.Enabled) { "Actif" } else { "Désactivé" }
        $UserTab_LastLogonTextBox.Text = if ($selectedUser.LastLogonDate) { $selectedUser.LastLogonDate.ToString("dd/MM/yyyy HH:mm:ss") } else { "Jamais" }
        $UserTab_MemberOfListBox.ItemsSource = $selectedUser.MemberOf
        
        # Gestion des managers
        $managers = @()
        foreach ($group in $selectedUser.MemberOf) {
            try {
                $groupObj = Get-ADGroup -Identity $group -Properties Members
                foreach ($member in $groupObj.Members) {
                    try {
                        $memberObj = Get-ADUser -Identity $member -Properties DisplayName, SamAccountName
                        $managers += "$($memberObj.DisplayName) ($($memberObj.SamAccountName))"
                    } catch {
                        # Ignorer les objets qui ne sont pas des utilisateurs
                        continue
                    }
                }
            } catch {
                # Ignorer les groupes qui ne peuvent pas être récupérés
                continue
            }
        }
        
        if ($managers.Count -gt 0) {
            $UserTab_ManagersListBox.ItemsSource = $managers | Select-Object -Unique
        } else {
            $UserTab_ManagersListBox.ItemsSource = @("Aucun manager")
        }
    }
})

#**************************************
# Panneau groupes
#**************************************

# Gestion du bouton de recherche pour les groupes
$GroupTab_SearchButton.Add_Click({
    # Initialisation du résultat
    $GroupTab_ResultListBox.ItemsSource = $null

    If ($GroupTab_GroupNameTextBox.Text -ne '') {
        $results = @(Get-ADGroup -filter "name -like '*$($GroupTab_GroupNameTextBox.Text)*'" -Properties DistinguishedName, Members | 
            ForEach-Object { [PSCustomObject]@{
                DisplayName="$($_.Name)"
                Name=$_.Name
                DistinguishedName=$_.DistinguishedName
                Members=$_.Members
            }} | 
            Sort-Object -Property DisplayName)
        
        If ($results.Length -ne 0) {
            $GroupTab_ResultListBox.ItemsSource = $results
            $GroupTab_ResultListBox.DisplayMemberPath = 'DisplayName'
            $GroupTab_ResultListBox.SelectedIndex = 0
        } Else {
            $GroupTab_ResultListBox.ItemsSource = @([PSCustomObject]@{
                DisplayName="Aucun résultat"
                Name=""
                DistinguishedName=""
                Members=@()
            })
            $GroupTab_ResultListBox.DisplayMemberPath = 'DisplayName'
            $GroupTab_ResultListBox.SelectedIndex = 0
        }
    } else {
        $GroupTab_ResultListBox.ItemsSource = @([PSCustomObject]@{
            DisplayName="Veuillez entrer un nom de groupe"
            Name=""
            DistinguishedName=""
            Members=@()
        })
        $GroupTab_ResultListBox.DisplayMemberPath = 'DisplayName'
        $GroupTab_ResultListBox.SelectedIndex = 0
    }
})

# Affichage des données du groupe sélectionné
$GroupTab_ResultListBox.Add_SelectionChanged({
    if ($GroupTab_ResultListBox.SelectedItem -ne $null) {
        $selectedGroup = $GroupTab_ResultListBox.SelectedItem
        $GroupTab_NameTextBox.Text = $selectedGroup.Name
        $GroupTab_DistinguishedNameTextBox.Text = $selectedGroup.DistinguishedName
        
        # Récupération des membres du groupe
        $members = @()
        foreach ($member in $selectedGroup.Members) {
            try {
                $memberObj = Get-ADObject -Identity $member -Properties DisplayName, SamAccountName
                if ($memberObj.objectClass -eq 'user') {
                    $members += "$($memberObj.DisplayName) ($($memberObj.SamAccountName))"
                } else {
                    $members += $memberObj.Name
                }
            } catch {
                $members += $member
            }
        }
        $GroupTab_MembersListBox.ItemsSource = $members
    }
})

#**************************************
#Configuration Event du bouton "Fermer"
#**************************************
$CloseButton.Add_Click({
    $MainWindow.DialogResult = $true
    $MainWindow.Close() | Out-Null
})


# Afficher la fenêtre
$MainWindow.ShowDialog() | Out-Null