# CognitiveTrainer_Fixed.ps1 - Fixed Stroop + All Games
# Run: powershell -ExecutionPolicy Bypass -File CognitiveTrainer_Fixed.ps1

Add-Type -AssemblyName PresentationFramework
Add-Type -AssemblyName PresentationCore
Add-Type -AssemblyName WindowsBase

# ============================================================
# STATE
# ============================================================
$script:score=0;$script:streak=0;$script:bestStreak=0;$script:level=1
$script:totalQ=0;$script:correctQ=0;$script:timeLeft=30;$script:gameActive=$false
$script:answer=0;$script:currentGame="";$script:gamesPlayed=0;$script:highScore=0
$script:qThisLvl=0;$script:puzzleHint="";$script:puzzleSteps=@();$script:elapsed=0
$script:schulteNext=1;$script:schulteSize=5
$script:stroopCorrectColor="";$script:stroopRound=0
$script:speedTarget=-1;$script:speedHits=0
$script:nbackN=2;$script:nbackHistory=@();$script:nbackStep=0;$script:nbackScore=0
$script:sudokuGrid=$null;$script:sudokuSolution=$null;$script:sudokuFixed=@{}
$script:selRow=-1;$script:selCol=-1;$script:sudokuTime=0;$script:mistakes=0;$script:hintsLeft=3
$script:noteMode=$false;$script:sudokuNotes=@{};$script:sudokuHistory=[System.Collections.ArrayList]::new()

function GC2([int]$r,[int]$c){return $script:sudokuGrid[$r,$c]}
function SC2([int]$r,[int]$c,[int]$v){$script:sudokuGrid[$r,$c]=$v}
function GS2([int]$r,[int]$c){return $script:sudokuSolution[$r,$c]}

$script:brainTeasers=@{
    "WaterJug"=@(
        @{Q="3L jug + 5L jug.`nSteps to measure 4L?";A=6;H="Fill 5, pour to 3, empty 3, pour 2, fill 5, pour to 3";S=@("Fill 5L","Pour to 3L (2L left)","Empty 3L","Pour 2L to 3L","Fill 5L","Pour to 3L = 4L left")}
        @{Q="5L jug + 2L jug.`nSteps to get 1L?";A=4;H="Fill 5, pour to 2, empty 2, pour rest";S=@("Fill 5L","Pour to 2L (3L left)","Empty 2L","Pour 3L to 2L (1L left)")}
    )
    "Weight"=@(
        @{Q="6kg + 4kg weights on a balance.`nHow many weights to measure 2kg?";A=2;H="Put on opposite sides: 6-4=2";S=@("6kg left pan","4kg + item right","Balance = item is 2kg")}
        @{Q="Weights: 1,3,9,27 kg.`nMin weights for exactly 5kg?";A=3;H="9-3-1=5 on balance";S=@("9kg on left","3kg+1kg+item on right","9=3+1+5")}
    )
    "Coin"=@(
        @{Q="12 coins, 1 lighter.`nMin weighings?";A=3;H="4v4v4, 2v2, 1v1";S=@("Weigh 4v4","Lighter group has fake","2v2","1v1")}
    )
    "Math"=@(
        @{Q="1+2+3+...+100 = ?";A=5050;H="50 pairs of 101";S=@("(1+100)x50=5050")}
        @{Q="999 x 999 = ?";A=998001;H="(1000-1)^2=1000000-2000+1";S=@("998001")}
        @{Q="Squares on 8x8 chess board?`n(All sizes, not just 64)";A=204;H="Sum of n^2 from 1 to 8";S=@("64+49+36+25+16+9+4+1=204")}
    )
}

# ============================================================
# XAML
# ============================================================
[xml]$xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
    xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
    Title="Cognitive Trainer" Width="1160" Height="820"
    WindowStartupLocation="CenterScreen" WindowStyle="None"
    AllowsTransparency="True" Background="Transparent" ResizeMode="CanMinimize">
<Window.Resources>
    <Style x:Key="ST" TargetType="Thumb"><Setter Property="Template"><Setter.Value>
        <ControlTemplate TargetType="Thumb"><Border x:Name="t" Background="#25FFFFFF" CornerRadius="3" Margin="1,0" MinHeight="18"/>
            <ControlTemplate.Triggers><Trigger Property="IsMouseOver" Value="True"><Setter TargetName="t" Property="Background" Value="#45FFFFFF"/></Trigger></ControlTemplate.Triggers>
        </ControlTemplate></Setter.Value></Setter></Style>
    <Style x:Key="DSB" TargetType="ScrollBar"><Setter Property="Width" Value="5"/><Setter Property="Background" Value="Transparent"/>
        <Setter Property="Template"><Setter.Value><ControlTemplate TargetType="ScrollBar"><Track x:Name="PART_Track" IsDirectionReversed="True">
            <Track.DecreaseRepeatButton><RepeatButton Command="ScrollBar.PageUpCommand" Opacity="0"/></Track.DecreaseRepeatButton>
            <Track.Thumb><Thumb Style="{StaticResource ST}"/></Track.Thumb>
            <Track.IncreaseRepeatButton><RepeatButton Command="ScrollBar.PageDownCommand" Opacity="0"/></Track.IncreaseRepeatButton>
        </Track></ControlTemplate></Setter.Value></Setter></Style>
    <Style x:Key="DSV" TargetType="ScrollViewer"><Setter Property="Template"><Setter.Value>
        <ControlTemplate TargetType="ScrollViewer"><Grid><Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="Auto"/></Grid.ColumnDefinitions>
            <ScrollContentPresenter Grid.Column="0"/><ScrollBar Grid.Column="1" Style="{StaticResource DSB}" Value="{TemplateBinding VerticalOffset}" Maximum="{TemplateBinding ScrollableHeight}" ViewportSize="{TemplateBinding ViewportHeight}" Visibility="{TemplateBinding ComputedVerticalScrollBarVisibility}"/>
        </Grid></ControlTemplate></Setter.Value></Setter></Style>
    <Style x:Key="Dot" TargetType="Button"><Setter Property="Width" Value="13"/><Setter Property="Height" Value="13"/><Setter Property="Cursor" Value="Hand"/>
        <Setter Property="Template"><Setter.Value><ControlTemplate TargetType="Button"><Ellipse x:Name="e" Fill="{TemplateBinding Background}" Opacity="0.8"/>
            <ControlTemplate.Triggers><Trigger Property="IsMouseOver" Value="True"><Setter TargetName="e" Property="Opacity" Value="1"/></Trigger></ControlTemplate.Triggers>
        </ControlTemplate></Setter.Value></Setter></Style>
    <Style x:Key="SqV" TargetType="Button"><Setter Property="Foreground" Value="White"/><Setter Property="FontSize" Value="12.5"/><Setter Property="FontWeight" Value="SemiBold"/><Setter Property="Cursor" Value="Hand"/>
        <Setter Property="Template"><Setter.Value><ControlTemplate TargetType="Button"><Grid>
            <Border x:Name="glow" CornerRadius="14" Opacity="0" Margin="-8"><Border.Effect><BlurEffect Radius="22"/></Border.Effect><Border.Background><SolidColorBrush Color="#6C5CE7"/></Border.Background></Border>
            <Border x:Name="body" CornerRadius="14" Padding="18,10" BorderThickness="1.2">
                <Border.Background><LinearGradientBrush StartPoint="0,0" EndPoint="0,1"><GradientStop Color="#1E1E30" Offset="0"/><GradientStop Color="#141420" Offset="1"/></LinearGradientBrush></Border.Background>
                <Border.BorderBrush><LinearGradientBrush StartPoint="0,0" EndPoint="0,1"><GradientStop Color="#40FFFFFF" Offset="0"/><GradientStop Color="#15FFFFFF" Offset="1"/></LinearGradientBrush></Border.BorderBrush>
                <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/></Border></Grid>
            <ControlTemplate.Triggers><Trigger Property="IsMouseOver" Value="True"><Setter TargetName="glow" Property="Opacity" Value="0.55"/>
                <Setter TargetName="body" Property="Background"><Setter.Value><SolidColorBrush Color="#5A4BD1"/></Setter.Value></Setter></Trigger>
                <Trigger Property="IsPressed" Value="True"><Setter TargetName="glow" Property="Opacity" Value="0.85"/></Trigger></ControlTemplate.Triggers>
        </ControlTemplate></Setter.Value></Setter></Style>
    <Style x:Key="SqG" TargetType="Button"><Setter Property="Foreground" Value="White"/><Setter Property="FontSize" Value="12.5"/><Setter Property="FontWeight" Value="SemiBold"/><Setter Property="Cursor" Value="Hand"/>
        <Setter Property="Template"><Setter.Value><ControlTemplate TargetType="Button"><Grid>
            <Border x:Name="glow" CornerRadius="14" Opacity="0" Margin="-8"><Border.Effect><BlurEffect Radius="22"/></Border.Effect><Border.Background><SolidColorBrush Color="#00B894"/></Border.Background></Border>
            <Border x:Name="body" CornerRadius="14" Padding="18,10" BorderThickness="1.2">
                <Border.Background><LinearGradientBrush StartPoint="0,0" EndPoint="0,1"><GradientStop Color="#1A2E28" Offset="0"/><GradientStop Color="#121E1A" Offset="1"/></LinearGradientBrush></Border.Background>
                <Border.BorderBrush><LinearGradientBrush StartPoint="0,0" EndPoint="0,1"><GradientStop Color="#40FFFFFF" Offset="0"/><GradientStop Color="#15FFFFFF" Offset="1"/></LinearGradientBrush></Border.BorderBrush>
                <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/></Border></Grid>
            <ControlTemplate.Triggers><Trigger Property="IsMouseOver" Value="True"><Setter TargetName="glow" Property="Opacity" Value="0.55"/></Trigger></ControlTemplate.Triggers>
        </ControlTemplate></Setter.Value></Setter></Style>
    <Style x:Key="SqY" TargetType="Button"><Setter Property="Foreground" Value="White"/><Setter Property="FontSize" Value="12.5"/><Setter Property="FontWeight" Value="SemiBold"/><Setter Property="Cursor" Value="Hand"/>
        <Setter Property="Template"><Setter.Value><ControlTemplate TargetType="Button"><Grid>
            <Border x:Name="glow" CornerRadius="14" Opacity="0" Margin="-8"><Border.Effect><BlurEffect Radius="22"/></Border.Effect><Border.Background><SolidColorBrush Color="#FDCB6E"/></Border.Background></Border>
            <Border x:Name="body" CornerRadius="14" Padding="18,10" BorderThickness="1.2">
                <Border.Background><LinearGradientBrush StartPoint="0,0" EndPoint="0,1"><GradientStop Color="#2E2818" Offset="0"/><GradientStop Color="#1E1A10" Offset="1"/></LinearGradientBrush></Border.Background>
                <Border.BorderBrush><LinearGradientBrush StartPoint="0,0" EndPoint="0,1"><GradientStop Color="#40FFFFFF" Offset="0"/><GradientStop Color="#15FFFFFF" Offset="1"/></LinearGradientBrush></Border.BorderBrush>
                <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/></Border></Grid>
            <ControlTemplate.Triggers><Trigger Property="IsMouseOver" Value="True"><Setter TargetName="glow" Property="Opacity" Value="0.55"/></Trigger></ControlTemplate.Triggers>
        </ControlTemplate></Setter.Value></Setter></Style>
    <Style x:Key="SqR" TargetType="Button"><Setter Property="Foreground" Value="White"/><Setter Property="FontSize" Value="12.5"/><Setter Property="FontWeight" Value="SemiBold"/><Setter Property="Cursor" Value="Hand"/>
        <Setter Property="Template"><Setter.Value><ControlTemplate TargetType="Button"><Grid>
            <Border x:Name="glow" CornerRadius="14" Opacity="0" Margin="-8"><Border.Effect><BlurEffect Radius="22"/></Border.Effect><Border.Background><SolidColorBrush Color="#E84855"/></Border.Background></Border>
            <Border x:Name="body" CornerRadius="14" Padding="18,10" BorderThickness="1.2">
                <Border.Background><LinearGradientBrush StartPoint="0,0" EndPoint="0,1"><GradientStop Color="#2E1A1C" Offset="0"/><GradientStop Color="#1E1214" Offset="1"/></LinearGradientBrush></Border.Background>
                <Border.BorderBrush><LinearGradientBrush StartPoint="0,0" EndPoint="0,1"><GradientStop Color="#40FFFFFF" Offset="0"/><GradientStop Color="#15FFFFFF" Offset="1"/></LinearGradientBrush></Border.BorderBrush>
                <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/></Border></Grid>
            <ControlTemplate.Triggers><Trigger Property="IsMouseOver" Value="True"><Setter TargetName="glow" Property="Opacity" Value="0.55"/></Trigger></ControlTemplate.Triggers>
        </ControlTemplate></Setter.Value></Setter></Style>
    <Style x:Key="SqD" TargetType="Button"><Setter Property="Foreground" Value="#CCC"/><Setter Property="FontSize" Value="12.5"/><Setter Property="FontWeight" Value="SemiBold"/><Setter Property="Cursor" Value="Hand"/>
        <Setter Property="Template"><Setter.Value><ControlTemplate TargetType="Button">
            <Border x:Name="body" CornerRadius="14" Padding="18,10" BorderThickness="1">
                <Border.Background><SolidColorBrush Color="White" Opacity="0.06"/></Border.Background>
                <Border.BorderBrush><SolidColorBrush Color="White" Opacity="0.12"/></Border.BorderBrush>
                <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/></Border>
            <ControlTemplate.Triggers><Trigger Property="IsMouseOver" Value="True"><Setter TargetName="body" Property="Background"><Setter.Value><SolidColorBrush Color="White" Opacity="0.12"/></Setter.Value></Setter></Trigger></ControlTemplate.Triggers>
        </ControlTemplate></Setter.Value></Setter></Style>
    <Style x:Key="SqLV" TargetType="Button"><Setter Property="Foreground" Value="White"/><Setter Property="FontSize" Value="12.5"/><Setter Property="FontWeight" Value="SemiBold"/><Setter Property="Cursor" Value="Hand"/>
        <Setter Property="Template"><Setter.Value><ControlTemplate TargetType="Button"><Grid>
            <Border x:Name="glow" CornerRadius="14" Opacity="0" Margin="-8"><Border.Effect><BlurEffect Radius="22"/></Border.Effect><Border.Background><SolidColorBrush Color="#A29BFE"/></Border.Background></Border>
            <Border x:Name="body" CornerRadius="14" Padding="18,10" BorderThickness="1.2">
                <Border.Background><LinearGradientBrush StartPoint="0,0" EndPoint="0,1"><GradientStop Color="#24203A" Offset="0"/><GradientStop Color="#181528" Offset="1"/></LinearGradientBrush></Border.Background>
                <Border.BorderBrush><LinearGradientBrush StartPoint="0,0" EndPoint="0,1"><GradientStop Color="#40FFFFFF" Offset="0"/><GradientStop Color="#15FFFFFF" Offset="1"/></LinearGradientBrush></Border.BorderBrush>
                <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/></Border></Grid>
            <ControlTemplate.Triggers><Trigger Property="IsMouseOver" Value="True"><Setter TargetName="glow" Property="Opacity" Value="0.55"/></Trigger></ControlTemplate.Triggers>
        </ControlTemplate></Setter.Value></Setter></Style>
    <Style x:Key="GC" TargetType="Button"><Setter Property="Cursor" Value="Hand"/><Setter Property="Template"><Setter.Value>
        <ControlTemplate TargetType="Button"><Border x:Name="bg" Background="#0AFFFFFF" CornerRadius="12" BorderThickness="1">
            <Border.BorderBrush><SolidColorBrush Color="White" Opacity="0.08"/></Border.BorderBrush><ContentPresenter/></Border>
            <ControlTemplate.Triggers><Trigger Property="IsMouseOver" Value="True"><Setter TargetName="bg" Property="Background" Value="#15FFFFFF"/></Trigger></ControlTemplate.Triggers>
        </ControlTemplate></Setter.Value></Setter></Style>
    <Style x:Key="Cell" TargetType="Button"><Setter Property="Foreground" Value="White"/><Setter Property="FontSize" Value="22"/><Setter Property="FontWeight" Value="Bold"/><Setter Property="Cursor" Value="Hand"/>
        <Setter Property="Template"><Setter.Value><ControlTemplate TargetType="Button">
            <Border x:Name="bg" CornerRadius="10" BorderThickness="1">
                <Border.Background><SolidColorBrush Color="White" Opacity="0.08"/></Border.Background>
                <Border.BorderBrush><SolidColorBrush Color="White" Opacity="0.06"/></Border.BorderBrush>
                <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/></Border>
            <ControlTemplate.Triggers><Trigger Property="IsMouseOver" Value="True"><Setter TargetName="bg" Property="Background"><Setter.Value><SolidColorBrush Color="White" Opacity="0.15"/></Setter.Value></Setter></Trigger></ControlTemplate.Triggers>
        </ControlTemplate></Setter.Value></Setter></Style>
    <Style x:Key="NP" TargetType="Button"><Setter Property="Foreground" Value="White"/><Setter Property="FontSize" Value="20"/><Setter Property="FontWeight" Value="SemiBold"/><Setter Property="Cursor" Value="Hand"/>
        <Setter Property="Template"><Setter.Value><ControlTemplate TargetType="Button"><Border x:Name="b" Background="#12FFFFFF" CornerRadius="10"><ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/></Border>
            <ControlTemplate.Triggers><Trigger Property="IsMouseOver" Value="True"><Setter TargetName="b" Property="Background" Value="#22FFFFFF"/></Trigger></ControlTemplate.Triggers>
        </ControlTemplate></Setter.Value></Setter></Style>
    <Style x:Key="Chip" TargetType="Button"><Setter Property="Foreground" Value="#AAA"/><Setter Property="FontSize" Value="11"/><Setter Property="Cursor" Value="Hand"/>
        <Setter Property="Template"><Setter.Value><ControlTemplate TargetType="Button"><Border x:Name="b" Background="#10FFFFFF" CornerRadius="10" Padding="14,5"><ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/></Border>
            <ControlTemplate.Triggers><Trigger Property="IsMouseOver" Value="True"><Setter TargetName="b" Property="Background" Value="#20FFFFFF"/></Trigger></ControlTemplate.Triggers>
        </ControlTemplate></Setter.Value></Setter></Style>
    <Style x:Key="SC" TargetType="Button"><Setter Property="Foreground" Value="White"/><Setter Property="FontSize" Value="20"/><Setter Property="FontWeight" Value="SemiBold"/><Setter Property="Cursor" Value="Hand"/>
        <Setter Property="Template"><Setter.Value><ControlTemplate TargetType="Button"><Border x:Name="bg" Background="#10FFFFFF" CornerRadius="4" BorderBrush="#0CFFFFFF" BorderThickness="0.5"><ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/></Border>
            <ControlTemplate.Triggers><Trigger Property="IsMouseOver" Value="True"><Setter TargetName="bg" Property="Background" Value="#20FFFFFF"/></Trigger></ControlTemplate.Triggers>
        </ControlTemplate></Setter.Value></Setter></Style>
    <Style x:Key="SN" TargetType="Button"><Setter Property="Foreground" Value="White"/><Setter Property="FontSize" Value="22"/><Setter Property="FontWeight" Value="SemiBold"/><Setter Property="Cursor" Value="Hand"/>
        <Setter Property="Template"><Setter.Value><ControlTemplate TargetType="Button"><Border x:Name="bg" Background="#15FFFFFF" CornerRadius="12"><ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/></Border>
            <ControlTemplate.Triggers><Trigger Property="IsMouseOver" Value="True"><Setter TargetName="bg" Property="Background" Value="#25FFFFFF"/></Trigger></ControlTemplate.Triggers>
        </ControlTemplate></Setter.Value></Setter></Style>
    <!-- Stroop color answer button -->
    <Style x:Key="StroopBtn" TargetType="Button"><Setter Property="FontSize" Value="16"/><Setter Property="FontWeight" Value="Bold"/><Setter Property="Cursor" Value="Hand"/>
        <Setter Property="Template"><Setter.Value><ControlTemplate TargetType="Button">
            <Border x:Name="bg" CornerRadius="12" BorderThickness="2" Padding="16,12">
                <Border.Background><SolidColorBrush Color="White" Opacity="0.06"/></Border.Background>
                <Border.BorderBrush><SolidColorBrush Color="White" Opacity="0.1"/></Border.BorderBrush>
                <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/></Border>
            <ControlTemplate.Triggers><Trigger Property="IsMouseOver" Value="True">
                <Setter TargetName="bg" Property="Background"><Setter.Value><SolidColorBrush Color="White" Opacity="0.15"/></Setter.Value></Setter>
                <Setter TargetName="bg" Property="BorderBrush"><Setter.Value><SolidColorBrush Color="White" Opacity="0.3"/></Setter.Value></Setter>
            </Trigger></ControlTemplate.Triggers>
        </ControlTemplate></Setter.Value></Setter></Style>
    <Style TargetType="ContextMenu"><Setter Property="Background" Value="#E8222222"/><Setter Property="BorderBrush" Value="#20FFFFFF"/><Setter Property="BorderThickness" Value="1"/>
        <Setter Property="Template"><Setter.Value><ControlTemplate TargetType="ContextMenu"><Border Background="{TemplateBinding Background}" BorderBrush="{TemplateBinding BorderBrush}" BorderThickness="1" CornerRadius="12" Padding="3,5">
            <Border.Effect><DropShadowEffect Color="Black" BlurRadius="25" ShadowDepth="5" Opacity="0.6"/></Border.Effect><StackPanel IsItemsHost="True"/></Border></ControlTemplate></Setter.Value></Setter></Style>
    <Style TargetType="MenuItem"><Setter Property="Foreground" Value="#DDD"/><Setter Property="FontSize" Value="12"/><Setter Property="Padding" Value="14,8"/>
        <Setter Property="Template"><Setter.Value><ControlTemplate TargetType="MenuItem"><Border x:Name="bg" Background="Transparent" CornerRadius="8" Margin="2,1" Padding="{TemplateBinding Padding}" Cursor="Hand"><ContentPresenter ContentSource="Header"/></Border>
            <ControlTemplate.Triggers><Trigger Property="IsHighlighted" Value="True"><Setter TargetName="bg" Property="Background" Value="#15FFFFFF"/></Trigger></ControlTemplate.Triggers>
        </ControlTemplate></Setter.Value></Setter></Style>
    <Style TargetType="Separator"><Setter Property="Height" Value="1"/><Setter Property="Background" Value="#12FFFFFF"/><Setter Property="Margin" Value="10,4"/></Style>
</Window.Resources>

<Border x:Name="MB" Margin="12" CornerRadius="16" BorderThickness="1">
    <Border.BorderBrush><SolidColorBrush Color="White" Opacity="0.1"/></Border.BorderBrush>
    <Border.Background><LinearGradientBrush StartPoint="0,0" EndPoint="1,1">
        <GradientStop Color="#F01A1A2E" Offset="0"/><GradientStop Color="#F016213E" Offset="0.5"/><GradientStop Color="#F00F3460" Offset="1"/>
    </LinearGradientBrush></Border.Background>
    <Border.Effect><DropShadowEffect Color="Black" BlurRadius="40" ShadowDepth="0" Opacity="0.7"/></Border.Effect>
    <Grid><Grid.RowDefinitions><RowDefinition Height="42"/><RowDefinition Height="*"/></Grid.RowDefinitions>
    <Border x:Name="TB" Grid.Row="0" Background="Transparent" CornerRadius="16,16,0,0"><Grid>
        <StackPanel Orientation="Horizontal" Margin="16,0" VerticalAlignment="Center">
            <Button x:Name="btnX" Style="{StaticResource Dot}" Background="#FF5F57" Margin="0,0,7,0"/>
            <Button x:Name="btnMn" Style="{StaticResource Dot}" Background="#FFBD2E" Margin="0,0,7,0"/>
            <Button x:Name="btnMx" Style="{StaticResource Dot}" Background="#28C840"/></StackPanel>
        <TextBlock Text="Cognitive Trainer" Foreground="#40FFFFFF" FontSize="11.5" FontWeight="SemiBold" HorizontalAlignment="Center" VerticalAlignment="Center"/>
    </Grid></Border>
    <Grid Grid.Row="1">

    <!-- HOME -->
    <Grid x:Name="sH"><ScrollViewer Style="{StaticResource DSV}" VerticalScrollBarVisibility="Auto">
        <StackPanel HorizontalAlignment="Center" MaxWidth="1020" Margin="0,16,0,30">
            <TextBlock Text="Cognitive Trainer" Foreground="White" FontSize="32" FontWeight="Bold" HorizontalAlignment="Center" Margin="0,0,0,4">
                <TextBlock.Effect><DropShadowEffect Color="#6C5CE7" BlurRadius="25" ShadowDepth="0" Opacity="0.35"/></TextBlock.Effect></TextBlock>
            <TextBlock Text="Brain Training + Vedic Maths + Puzzles + Sudoku" Foreground="#40FFFFFF" FontSize="11" HorizontalAlignment="Center" Margin="0,0,0,10"/>
            <StackPanel Orientation="Horizontal" HorizontalAlignment="Center" Margin="0,0,0,18">
                <Border Background="#08FFFFFF" CornerRadius="10" Padding="12,4" Margin="3,0"><TextBlock x:Name="lHP" Text="0 played" Foreground="#60CDFF" FontSize="10" FontWeight="SemiBold"/></Border>
                <Border Background="#08FFFFFF" CornerRadius="10" Padding="12,4" Margin="3,0"><TextBlock x:Name="lHH" Text="Best: 0" Foreground="#FDCB6E" FontSize="10" FontWeight="SemiBold"/></Border>
                <Border Background="#08FFFFFF" CornerRadius="10" Padding="12,4" Margin="3,0"><TextBlock x:Name="lHS" Text="Streak: 0" Foreground="#FD79A8" FontSize="10" FontWeight="SemiBold"/></Border>
            </StackPanel>
            <WrapPanel HorizontalAlignment="Center" Margin="0,0,0,16">
                <Button x:Name="cAll" Style="{StaticResource SqD}" Margin="4,4" Content="All"/>
                <Button x:Name="cBrn" Style="{StaticResource SqV}" Margin="4,4" Content="Brain Training"/>
                <Button x:Name="cVed" Style="{StaticResource SqG}" Margin="4,4" Content="Vedic Maths"/>
                <Button x:Name="cTes" Style="{StaticResource SqY}" Margin="4,4" Content="Brain Teasers"/>
                <Button x:Name="cSud" Style="{StaticResource SqR}" Margin="4,4" Content="Sudoku"/>
            </WrapPanel>
            <StackPanel x:Name="hCards"/>
        </StackPanel></ScrollViewer>
    </Grid>

    <!-- GRID GAME (Schulte/Speed/NBack) - uses UniformGrid -->
    <Grid x:Name="sG" Visibility="Collapsed"><Grid.RowDefinitions><RowDefinition Height="48"/><RowDefinition Height="*"/></Grid.RowDefinitions>
        <Border Grid.Row="0" Background="#08FFFFFF" Padding="12,0"><Grid>
            <StackPanel Orientation="Horizontal" VerticalAlignment="Center">
                <Button x:Name="gBk" Style="{StaticResource Chip}" Content="Back" Margin="0,0,12,0"/>
                <TextBlock x:Name="gTl" Text="" Foreground="White" FontSize="14" FontWeight="Bold" VerticalAlignment="Center"/></StackPanel>
            <StackPanel Orientation="Horizontal" HorizontalAlignment="Center" VerticalAlignment="Center">
                <Border Background="#0CFFFFFF" CornerRadius="8" Padding="10,4" Margin="3,0"><StackPanel HorizontalAlignment="Center">
                    <TextBlock Text="SCORE" Foreground="#35FFFFFF" FontSize="7" FontWeight="Bold" HorizontalAlignment="Center"/>
                    <TextBlock x:Name="gSc" Text="0" Foreground="#FDCB6E" FontSize="15" FontWeight="Bold" HorizontalAlignment="Center"/></StackPanel></Border>
                <Border Background="#0CFFFFFF" CornerRadius="8" Padding="10,4" Margin="3,0"><StackPanel HorizontalAlignment="Center">
                    <TextBlock Text="TIME" Foreground="#35FFFFFF" FontSize="7" FontWeight="Bold" HorizontalAlignment="Center"/>
                    <TextBlock x:Name="gTm" Text="0:00" Foreground="White" FontSize="15" FontWeight="Bold" HorizontalAlignment="Center"/></StackPanel></Border>
                <Border Background="#0CFFFFFF" CornerRadius="8" Padding="10,4" Margin="3,0"><StackPanel HorizontalAlignment="Center">
                    <TextBlock x:Name="gStL" Text="NEXT" Foreground="#35FFFFFF" FontSize="7" FontWeight="Bold" HorizontalAlignment="Center"/>
                    <TextBlock x:Name="gSt" Text="" Foreground="#00B894" FontSize="15" FontWeight="Bold" HorizontalAlignment="Center"/></StackPanel></Border>
            </StackPanel></Grid></Border>
        <StackPanel Grid.Row="1" VerticalAlignment="Center" HorizontalAlignment="Center">
            <TextBlock x:Name="gInstr" Text="" Foreground="#40FFFFFF" FontSize="12" HorizontalAlignment="Center" Margin="0,0,0,10" TextWrapping="Wrap" TextAlignment="Center" MaxWidth="500"/>
            <UniformGrid x:Name="gGrid" Width="480" Height="480"/>
            <TextBlock x:Name="gFb" Text="" Foreground="#00B894" FontSize="16" FontWeight="Bold" HorizontalAlignment="Center" Margin="0,10,0,0"/>
        </StackPanel>
    </Grid>

    <!-- STROOP GAME - FIXED LAYOUT: word on top, buttons below -->
    <Grid x:Name="sSt" Visibility="Collapsed"><Grid.RowDefinitions><RowDefinition Height="48"/><RowDefinition Height="*"/></Grid.RowDefinitions>
        <Border Grid.Row="0" Background="#08FFFFFF" Padding="12,0"><Grid>
            <StackPanel Orientation="Horizontal" VerticalAlignment="Center">
                <Button x:Name="stBk" Style="{StaticResource Chip}" Content="Back" Margin="0,0,12,0"/>
                <TextBlock Text="COLOR STROOP TEST" Foreground="White" FontSize="14" FontWeight="Bold" VerticalAlignment="Center"/></StackPanel>
            <StackPanel Orientation="Horizontal" HorizontalAlignment="Center" VerticalAlignment="Center">
                <Border Background="#0CFFFFFF" CornerRadius="8" Padding="10,4" Margin="3,0"><StackPanel HorizontalAlignment="Center">
                    <TextBlock Text="CORRECT" Foreground="#35FFFFFF" FontSize="7" FontWeight="Bold" HorizontalAlignment="Center"/>
                    <TextBlock x:Name="stSc" Text="0" Foreground="#00B894" FontSize="15" FontWeight="Bold" HorizontalAlignment="Center"/></StackPanel></Border>
                <Border Background="#0CFFFFFF" CornerRadius="8" Padding="10,4" Margin="3,0"><StackPanel HorizontalAlignment="Center">
                    <TextBlock Text="WRONG" Foreground="#35FFFFFF" FontSize="7" FontWeight="Bold" HorizontalAlignment="Center"/>
                    <TextBlock x:Name="stWr" Text="0" Foreground="#E84855" FontSize="15" FontWeight="Bold" HorizontalAlignment="Center"/></StackPanel></Border>
                <Border Background="#0CFFFFFF" CornerRadius="8" Padding="10,4" Margin="3,0"><StackPanel HorizontalAlignment="Center">
                    <TextBlock Text="ROUND" Foreground="#35FFFFFF" FontSize="7" FontWeight="Bold" HorizontalAlignment="Center"/>
                    <TextBlock x:Name="stRd" Text="0/20" Foreground="White" FontSize="15" FontWeight="Bold" HorizontalAlignment="Center"/></StackPanel></Border>
                <Border Background="#0CFFFFFF" CornerRadius="8" Padding="10,4" Margin="3,0"><StackPanel HorizontalAlignment="Center">
                    <TextBlock Text="TIME" Foreground="#35FFFFFF" FontSize="7" FontWeight="Bold" HorizontalAlignment="Center"/>
                    <TextBlock x:Name="stTm" Text="0:00" Foreground="White" FontSize="15" FontWeight="Bold" HorizontalAlignment="Center"/></StackPanel></Border>
            </StackPanel></Grid></Border>

        <StackPanel Grid.Row="1" VerticalAlignment="Center" HorizontalAlignment="Center" MaxWidth="550">
            <TextBlock Text="What INK COLOR is this word printed in?" Foreground="#50FFFFFF" FontSize="12" HorizontalAlignment="Center" Margin="0,0,0,16"/>

            <!-- THE STROOP WORD - displayed large and clear -->
            <Border Background="#08FFFFFF" CornerRadius="20" Padding="40,30" Margin="0,0,0,24" HorizontalAlignment="Center" MinWidth="300"
                    BorderThickness="1">
                <Border.BorderBrush><SolidColorBrush Color="White" Opacity="0.1"/></Border.BorderBrush>
                <TextBlock x:Name="stWord" Text="RED" FontSize="56" FontWeight="Bold" HorizontalAlignment="Center"
                           Foreground="#60CDFF"/>
            </Border>

            <!-- Answer buttons - 2 rows of 3 -->
            <TextBlock Text="Click the button that matches the INK COLOR above:" Foreground="#40FFFFFF" FontSize="11" HorizontalAlignment="Center" Margin="0,0,0,12"/>

            <UniformGrid x:Name="stBtns" Rows="2" Columns="3" Width="500" Height="140"/>

            <TextBlock x:Name="stFb" Text="" Foreground="#00B894" FontSize="18" FontWeight="Bold" HorizontalAlignment="Center" Margin="0,16,0,0"/>
        </StackPanel>
    </Grid>

    <!-- ARITHMETIC -->
    <Grid x:Name="sA" Visibility="Collapsed"><Grid.RowDefinitions><RowDefinition Height="48"/><RowDefinition Height="3"/><RowDefinition Height="*"/></Grid.RowDefinitions>
        <Border Grid.Row="0" Background="#08FFFFFF" Padding="12,0"><Grid>
            <StackPanel Orientation="Horizontal" VerticalAlignment="Center">
                <Button x:Name="aBk" Style="{StaticResource Chip}" Content="Back" Margin="0,0,12,0"/>
                <StackPanel><TextBlock x:Name="aTl" Text="" Foreground="White" FontSize="13" FontWeight="Bold"/>
                    <TextBlock x:Name="aDf" Text="" Foreground="#00B894" FontSize="8.5" FontWeight="Bold"/></StackPanel></StackPanel>
            <StackPanel Orientation="Horizontal" HorizontalAlignment="Center" VerticalAlignment="Center">
                <Border Background="#0CFFFFFF" CornerRadius="8" Padding="8,3" Margin="3,0"><StackPanel HorizontalAlignment="Center">
                    <TextBlock Text="SCORE" Foreground="#35FFFFFF" FontSize="7" FontWeight="Bold" HorizontalAlignment="Center"/>
                    <TextBlock x:Name="aSc" Text="0" Foreground="#FDCB6E" FontSize="14" FontWeight="Bold" HorizontalAlignment="Center"/></StackPanel></Border>
                <Border Background="#0CFFFFFF" CornerRadius="8" Padding="8,3" Margin="3,0"><StackPanel HorizontalAlignment="Center">
                    <TextBlock Text="STREAK" Foreground="#35FFFFFF" FontSize="7" FontWeight="Bold" HorizontalAlignment="Center"/>
                    <TextBlock x:Name="aSk" Text="0" Foreground="#FD79A8" FontSize="14" FontWeight="Bold" HorizontalAlignment="Center"/></StackPanel></Border>
            </StackPanel>
            <TextBlock x:Name="aTm" Text="" Foreground="White" FontSize="18" FontWeight="Bold" HorizontalAlignment="Right" VerticalAlignment="Center" Margin="0,0,8,0"/>
        </Grid></Border>
        <Grid Grid.Row="1" Background="#12FFFFFF"><Border x:Name="tBar" Background="#6C5CE7" HorizontalAlignment="Left" CornerRadius="1.5">
            <Border.Effect><DropShadowEffect Color="#6C5CE7" BlurRadius="8" ShadowDepth="0" Opacity="0.5"/></Border.Effect></Border></Grid>
        <Grid Grid.Row="2"><Grid.RowDefinitions><RowDefinition Height="*"/><RowDefinition Height="Auto"/></Grid.RowDefinitions>
            <StackPanel Grid.Row="0" VerticalAlignment="Center" HorizontalAlignment="Center">
                <Border CornerRadius="18" Padding="40,18" Margin="0,0,0,14" MinWidth="620" BorderThickness="1">
                    <Border.Background><SolidColorBrush Color="White" Opacity="0.06"/></Border.Background>
                    <Border.BorderBrush><SolidColorBrush Color="White" Opacity="0.1"/></Border.BorderBrush>
                    <StackPanel HorizontalAlignment="Center">
                        <TextBlock x:Name="aQ" Text="" Foreground="White" FontSize="18" FontWeight="Bold" HorizontalAlignment="Center" TextWrapping="Wrap" TextAlignment="Center" MaxWidth="580" LineHeight="26"/>
                        <TextBlock x:Name="aFb" Text="" FontSize="13" FontWeight="SemiBold" Foreground="#00B894" HorizontalAlignment="Center" Margin="0,8,0,0"/></StackPanel></Border>
                <Border CornerRadius="14" Padding="6" Margin="0,0,0,12" Width="480" BorderThickness="1">
                    <Border.Background><SolidColorBrush Color="White" Opacity="0.06"/></Border.Background>
                    <Border.BorderBrush><SolidColorBrush Color="White" Opacity="0.1"/></Border.BorderBrush>
                    <Grid><Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="Auto"/></Grid.ColumnDefinitions>
                        <TextBox x:Name="aIn" Grid.Column="0" FontSize="22" FontWeight="Bold" FontFamily="Consolas" Foreground="White" Background="Transparent" BorderThickness="0" Padding="14,6" CaretBrush="#A29BFE" VerticalContentAlignment="Center" MaxLength="15"/>
                        <Button x:Name="aGo" Grid.Column="1" Style="{StaticResource SqV}" Content="GO" Width="70" FontSize="16"/></Grid></Border>
                <Border CornerRadius="14" Padding="8" Width="480" BorderThickness="1">
                    <Border.Background><SolidColorBrush Color="White" Opacity="0.04"/></Border.Background>
                    <Border.BorderBrush><SolidColorBrush Color="White" Opacity="0.06"/></Border.BorderBrush>
                    <UniformGrid Rows="4" Columns="3" x:Name="npG"/></Border>
                <Button x:Name="aHint" Style="{StaticResource SqLV}" Content="Show Hint" Margin="0,10,0,0" HorizontalAlignment="Center" Visibility="Collapsed"/>
            </StackPanel>
            <Border x:Name="tPnl" Grid.Row="1" Padding="14,8" Margin="20,0,20,8" CornerRadius="14" Visibility="Collapsed" BorderThickness="1">
                <Border.Background><SolidColorBrush Color="#6C5CE7" Opacity="0.06"/></Border.Background>
                <Border.BorderBrush><SolidColorBrush Color="#6C5CE7" Opacity="0.15"/></Border.BorderBrush>
                <StackPanel><TextBlock x:Name="tT" Text="" Foreground="#A29BFE" FontSize="12" FontWeight="Bold"/>
                    <TextBlock x:Name="tB" Text="" Foreground="#50FFFFFF" FontSize="10" TextWrapping="Wrap" Margin="0,3,0,0" LineHeight="15"/></StackPanel></Border>
        </Grid>
    </Grid>

    <!-- SUDOKU -->
    <Grid x:Name="sS" Visibility="Collapsed"><Grid.RowDefinitions><RowDefinition Height="48"/><RowDefinition Height="*"/></Grid.RowDefinitions>
        <Border Grid.Row="0" Background="#08FFFFFF" Padding="12,0"><Grid>
            <StackPanel Orientation="Horizontal" VerticalAlignment="Center">
                <Button x:Name="sBk" Style="{StaticResource Chip}" Content="Back" Margin="0,0,12,0"/>
                <StackPanel><TextBlock x:Name="sTl" Text="SUDOKU" Foreground="White" FontSize="13" FontWeight="Bold"/>
                    <TextBlock x:Name="sDf" Text="" Foreground="#00B894" FontSize="8.5" FontWeight="Bold"/></StackPanel></StackPanel>
            <StackPanel Orientation="Horizontal" HorizontalAlignment="Center" VerticalAlignment="Center">
                <Border Background="#0CFFFFFF" CornerRadius="8" Padding="8,3" Margin="3,0"><StackPanel HorizontalAlignment="Center">
                    <TextBlock Text="TIME" Foreground="#35FFFFFF" FontSize="7" FontWeight="Bold" HorizontalAlignment="Center"/>
                    <TextBlock x:Name="ssTm" Text="0:00" Foreground="White" FontSize="14" FontWeight="Bold" HorizontalAlignment="Center"/></StackPanel></Border>
                <Border Background="#0CFFFFFF" CornerRadius="8" Padding="8,3" Margin="3,0"><StackPanel HorizontalAlignment="Center">
                    <TextBlock Text="ERRORS" Foreground="#35FFFFFF" FontSize="7" FontWeight="Bold" HorizontalAlignment="Center"/>
                    <TextBlock x:Name="ssEr" Text="0/3" Foreground="White" FontSize="14" FontWeight="Bold" HorizontalAlignment="Center"/></StackPanel></Border>
                <Border Background="#0CFFFFFF" CornerRadius="8" Padding="8,3" Margin="3,0"><StackPanel HorizontalAlignment="Center">
                    <TextBlock Text="LEFT" Foreground="#35FFFFFF" FontSize="7" FontWeight="Bold" HorizontalAlignment="Center"/>
                    <TextBlock x:Name="ssLf" Text="0" Foreground="#FDCB6E" FontSize="14" FontWeight="Bold" HorizontalAlignment="Center"/></StackPanel></Border>
            </StackPanel></Grid></Border>
        <Grid Grid.Row="1" Margin="14,6"><Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="Auto"/></Grid.ColumnDefinitions>
            <Viewbox Grid.Column="0" Stretch="Uniform" HorizontalAlignment="Center" VerticalAlignment="Center" MaxWidth="520" MaxHeight="520" Margin="0,0,12,0">
                <Border CornerRadius="8" Padding="2.5"><Border.Background><SolidColorBrush Color="White" Opacity="0.18"/></Border.Background>
                    <Grid x:Name="ssGr" Width="504" Height="504"/></Border></Viewbox>
            <StackPanel Grid.Column="1" Width="184" VerticalAlignment="Center">
                <UniformGrid x:Name="ssNm" Rows="3" Columns="3" Width="170" Height="170"/>
                <UniformGrid Rows="2" Columns="2" Width="170" Height="72" Margin="0,8,0,0">
                    <Button x:Name="ssUn" Style="{StaticResource Chip}" Content="Undo" Margin="2"/>
                    <Button x:Name="ssEs" Style="{StaticResource Chip}" Content="Erase" Margin="2"/>
                    <Button x:Name="ssNo" Style="{StaticResource Chip}" Content="Notes" Margin="2"/>
                    <Button x:Name="ssHi" Style="{StaticResource Chip}" Content="Hint" Margin="2"/></UniformGrid>
                <Button x:Name="ssNw" Style="{StaticResource SqV}" Content="New" Margin="0,8,0,0" HorizontalAlignment="Stretch"/>
                <TextBlock x:Name="ssFb" Text="" Foreground="#00B894" FontSize="11" FontWeight="SemiBold" HorizontalAlignment="Center" Margin="0,6,0,0" TextWrapping="Wrap"/>
            </StackPanel></Grid>
    </Grid>

    <!-- RESULT -->
    <Grid x:Name="sR" Visibility="Collapsed"><StackPanel VerticalAlignment="Center" HorizontalAlignment="Center">
        <TextBlock Text="Complete!" Foreground="#FDCB6E" FontSize="30" FontWeight="Bold" HorizontalAlignment="Center" Margin="0,0,0,16"/>
        <Border CornerRadius="18" Padding="36,16" Margin="0,0,0,14" MinWidth="360" BorderThickness="1">
            <Border.Background><SolidColorBrush Color="White" Opacity="0.06"/></Border.Background>
            <Border.BorderBrush><SolidColorBrush Color="White" Opacity="0.1"/></Border.BorderBrush>
            <StackPanel HorizontalAlignment="Center"><TextBlock Text="SCORE" Foreground="#35FFFFFF" FontSize="9" FontWeight="Bold" HorizontalAlignment="Center"/>
                <TextBlock x:Name="rSc" Text="0" Foreground="#FDCB6E" FontSize="48" FontWeight="Light" HorizontalAlignment="Center"/>
                <TextBlock x:Name="rHi" Text="" Foreground="#FD79A8" FontSize="11" FontWeight="Bold" HorizontalAlignment="Center"/></StackPanel></Border>
        <StackPanel Orientation="Horizontal" HorizontalAlignment="Center">
            <Button x:Name="rAg" Style="{StaticResource SqV}" Content="Again" Width="170" Margin="0,0,8,0"/>
            <Button x:Name="rMn" Style="{StaticResource SqD}" Content="Menu" Width="170"/></StackPanel>
    </StackPanel></Grid>

    </Grid></Grid></Border>
</Window>
"@

try{$rd=New-Object System.Xml.XmlNodeReader $xaml;$w=[Windows.Markup.XamlReader]::Load($rd)}catch{Write-Host "XAML: $($_.Exception.Message)" -ForegroundColor Red;return}

# ============================================================
# CONTROLS
# ============================================================
$MB=$w.FindName("MB");$TB=$w.FindName("TB");$btnX=$w.FindName("btnX");$btnMn=$w.FindName("btnMn");$btnMx=$w.FindName("btnMx")
$sH=$w.FindName("sH");$sG=$w.FindName("sG");$sSt=$w.FindName("sSt");$sA=$w.FindName("sA");$sS=$w.FindName("sS");$sR=$w.FindName("sR")
$lHP=$w.FindName("lHP");$lHH=$w.FindName("lHH");$lHS=$w.FindName("lHS");$hCards=$w.FindName("hCards")
$cAll=$w.FindName("cAll");$cBrn=$w.FindName("cBrn");$cVed=$w.FindName("cVed");$cTes=$w.FindName("cTes");$cSud=$w.FindName("cSud")
$gBk=$w.FindName("gBk");$gTl=$w.FindName("gTl");$gSc=$w.FindName("gSc");$gTm=$w.FindName("gTm");$gStL=$w.FindName("gStL");$gSt=$w.FindName("gSt");$gGrid=$w.FindName("gGrid");$gInstr=$w.FindName("gInstr");$gFb=$w.FindName("gFb")
$stBk=$w.FindName("stBk");$stSc=$w.FindName("stSc");$stWr=$w.FindName("stWr");$stRd=$w.FindName("stRd");$stTm=$w.FindName("stTm");$stWord=$w.FindName("stWord");$stBtns=$w.FindName("stBtns");$stFb=$w.FindName("stFb")
$aBk=$w.FindName("aBk");$aTl=$w.FindName("aTl");$aDf=$w.FindName("aDf");$aSc=$w.FindName("aSc");$aSk=$w.FindName("aSk");$aTm=$w.FindName("aTm");$tBar=$w.FindName("tBar");$aQ=$w.FindName("aQ");$aFb=$w.FindName("aFb");$aIn=$w.FindName("aIn");$aGo=$w.FindName("aGo");$npG=$w.FindName("npG");$aHint=$w.FindName("aHint");$tPnl=$w.FindName("tPnl");$tT=$w.FindName("tT");$tB=$w.FindName("tB")
$sBk=$w.FindName("sBk");$sTl=$w.FindName("sTl");$sDf=$w.FindName("sDf");$ssTm=$w.FindName("ssTm");$ssEr=$w.FindName("ssEr");$ssLf=$w.FindName("ssLf");$ssGr=$w.FindName("ssGr");$ssNm=$w.FindName("ssNm");$ssUn=$w.FindName("ssUn");$ssEs=$w.FindName("ssEs");$ssNo=$w.FindName("ssNo");$ssHi=$w.FindName("ssHi");$ssNw=$w.FindName("ssNw");$ssFb=$w.FindName("ssFb")
$rSc=$w.FindName("rSc");$rHi=$w.FindName("rHi");$rAg=$w.FindName("rAg");$rMn=$w.FindName("rMn")

function NB([string]$c){[System.Windows.Media.BrushConverter]::new().ConvertFrom($c)}
function Go($n){$sH.Visibility="Collapsed";$sG.Visibility="Collapsed";$sSt.Visibility="Collapsed";$sA.Visibility="Collapsed";$sS.Visibility="Collapsed";$sR.Visibility="Collapsed"
    switch($n){"Home"{$sH.Visibility="Visible"}"Grid"{$sG.Visibility="Visible"}"Stroop"{$sSt.Visibility="Visible"}"Arith"{$sA.Visibility="Visible"}"Sudoku"{$sS.Visibility="Visible"}"Result"{$sR.Visibility="Visible"}}}

# Title bar
$TB.Add_MouseLeftButtonDown({if($_.ClickCount -eq 2){if($w.WindowState -eq 'Maximized'){$w.WindowState='Normal'}else{$w.WindowState='Maximized'}}else{try{$w.DragMove()}catch{}}})
$btnX.Add_Click({$w.Close()});$btnMn.Add_Click({$w.WindowState='Minimized'})
$btnMx.Add_Click({if($w.WindowState -eq 'Maximized'){$w.WindowState='Normal'}else{$w.WindowState='Maximized'}})
$w.Add_StateChanged({if($w.WindowState -eq 'Maximized'){$MB.Margin=[System.Windows.Thickness]::new(0);$MB.CornerRadius=[System.Windows.CornerRadius]::new(0);$MB.Effect=$null;$TB.CornerRadius=[System.Windows.CornerRadius]::new(0)}else{$MB.Margin=[System.Windows.Thickness]::new(12);$MB.CornerRadius=[System.Windows.CornerRadius]::new(16);$sh=New-Object System.Windows.Media.Effects.DropShadowEffect;$sh.Color=[System.Windows.Media.Colors]::Black;$sh.BlurRadius=40;$sh.ShadowDepth=0;$sh.Opacity=0.7;$MB.Effect=$sh;$TB.CornerRadius=[System.Windows.CornerRadius]::new(16,16,0,0)}})

$ctx=New-Object System.Windows.Controls.ContextMenu
foreach($it in @("Reset","---","About","---","Exit")){if($it -eq "---"){$ctx.Items.Add((New-Object System.Windows.Controls.Separator))|Out-Null}else{$mi=New-Object System.Windows.Controls.MenuItem;$mi.Header=$it;$mi.Tag=$it;$mi.Add_Click({switch($this.Tag){"Reset"{$script:gamesPlayed=0;$script:highScore=0;$script:bestStreak=0;RH}"About"{[System.Windows.MessageBox]::Show("Cognitive Trainer - Fixed Stroop Edition","About","OK","Information")|Out-Null}"Exit"{$w.Close()}}});$ctx.Items.Add($mi)|Out-Null}}
$MB.ContextMenu=$ctx

# Timer
$script:gt=New-Object System.Windows.Threading.DispatcherTimer;$script:gt.Interval=[TimeSpan]::FromSeconds(1)
$script:ft=New-Object System.Windows.Threading.DispatcherTimer;$script:ft.Interval=[TimeSpan]::FromMilliseconds(1400)
$script:ft.Add_Tick({$aFb.Text="";$script:ft.Stop()})
$script:nbt=New-Object System.Windows.Threading.DispatcherTimer;$script:nbt.Interval=[TimeSpan]::FromMilliseconds(2500)

$script:gt.Add_Tick({
    if(-not $script:gameActive){return}
    $script:elapsed++
    if($script:currentGame -match "Schulte|Speed|NBack"){$m=[math]::Floor($script:elapsed/60);$s=$script:elapsed%60;$gTm.Text=("{0}:{1:D2}" -f $m,$s);return}
    if($script:currentGame -eq "Stroop"){$m=[math]::Floor($script:elapsed/60);$s=$script:elapsed%60;$stTm.Text=("{0}:{1:D2}" -f $m,$s);return}
    if($script:currentGame -like "Sudoku*"){$script:sudokuTime++;$m=[math]::Floor($script:sudokuTime/60);$s=$script:sudokuTime%60;$ssTm.Text=("{0}:{1:D2}" -f $m,$s);return}
    if($script:timeLeft -le 0){return};$script:timeLeft--;$aTm.Text="$($script:timeLeft)s"
    $maxT=if($script:currentGame -match "Speed|VSpeed"){60}elseif($script:currentGame -match "Q$"){120}else{30}
    $pct=[math]::Max(0,$script:timeLeft/$maxT);$tBar.Width=1140*$pct
    if($pct -gt 0.5){$tBar.Background=NB "#6C5CE7";$aTm.Foreground=NB "White"}elseif($pct -gt 0.25){$tBar.Background=NB "#FDCB6E";$aTm.Foreground=NB "#FDCB6E"}else{$tBar.Background=NB "#E84855";$aTm.Foreground=NB "#E84855"}
    if($script:timeLeft -le 0){EndArith}
})

# ============================================================
# GAME DEFINITIONS
# ============================================================
$script:allG = @(
    @{T="Schulte 5x5";D="Click 1-25 in order, eyes center";I="5x5";A="#6C5CE7";M="Schulte5";C="Brain";Df="Medium";Ty="grid"}
    @{T="Schulte 7x7";D="Click 1-49, peripheral vision";I="7x7";A="#6C5CE7";M="Schulte7";C="Brain";Df="Hard";Ty="grid"}
    @{T="Color Stroop";D="Click INK COLOR not the word";I="CLR";A="#FD79A8";M="Stroop";C="Brain";Df="Medium";Ty="stroop"}
    @{T="Speed Grid";D="Tap highlighted cells fast";I="TAP";A="#00B894";M="SpeedGrid";C="Brain";Df="Easy";Ty="grid"}
    @{T="N-Back (N=2)";D="Match position 2 steps ago";I="N=2";A="#A29BFE";M="NBack2";C="Brain";Df="Hard";Ty="grid"}
    @{T="11 Sandwich";D="Multiply by 11";I="x11";A="#6C5CE7";M="Sand11";C="Vedic";Df="Medium";Ty="arith";Tr="Split, SUM middle: 34x11=374"}
    @{T="Ghost Base";D="Near-100 multiply";I="~100";A="#6C5CE7";M="Ghost";C="Vedic";Df="Hard";Ty="arith";Tr="97x96: cross 93, mult 12->9312"}
    @{T="Sparkle Square";D="Square ending in 5";I="^25";A="#6C5CE7";M="Sparkle";C="Vedic";Df="Medium";Ty="arith";Tr="35^2: 3x4=12, +25=1225"}
    @{T="Last Stand";D="Subtract from 1000";I="-K";A="#6C5CE7";M="Last";C="Vedic";Df="Medium";Ty="arith";Tr="All from 9, last from 10"}
    @{T="Vedic Speed";D="All tricks 60s";I="V!";A="#6C5CE7";M="VSpeed";C="Vedic";Df="Hard";Ty="arith"}
    @{T="Water Jugs";D="Measure exact litres";I="JUG";A="#A29BFE";M="WaterQ";C="Teaser";Df="Hard";Ty="arith";Tm=120}
    @{T="Weight Balance";D="6kg+4kg = measure 2kg";I="KG";A="#FDCB6E";M="WeightQ";C="Teaser";Df="Hard";Ty="arith";Tm=120}
    @{T="Coin Puzzle";D="Find the fake coin";I="COIN";A="#00B894";M="CoinQ";C="Teaser";Df="Hard";Ty="arith";Tm=120}
    @{T="Math Tricks";D="Gauss, chess, patterns";I="=!";A="#E84855";M="TrickQ";C="Teaser";Df="Medium";Ty="arith";Tm=120}
    @{T="Easy Sudoku";D="45+ clues";I="S:E";A="#00B894";M="SudokuEasy";C="Sudoku";Df="Easy";Ty="sudoku"}
    @{T="Medium Sudoku";D="35 clues";I="S:M";A="#FDCB6E";M="SudokuMedium";C="Sudoku";Df="Medium";Ty="sudoku"}
    @{T="Hard Sudoku";D="25 clues";I="S:H";A="#E84855";M="SudokuHard";C="Sudoku";Df="Hard";Ty="sudoku"}
)

# ============================================================
# HOME
# ============================================================
function BH($filt){$hCards.Children.Clear();$list=if($filt){$script:allG|Where-Object{$_.C -eq $filt}}else{$script:allG};$cats=$list|Group-Object -Property C
    foreach($cat in $cats){$sp=New-Object System.Windows.Controls.StackPanel;$sp.Orientation="Horizontal";$sp.Margin=[System.Windows.Thickness]::new(0,6,0,8)
        $tb2=New-Object System.Windows.Controls.TextBlock;$tb2.Text=$cat.Name.ToUpper();$tb2.Foreground=NB "#30FFFFFF";$tb2.FontSize=10;$tb2.FontWeight="Bold";$tb2.VerticalAlignment="Center";$tb2.Margin=[System.Windows.Thickness]::new(0,0,10,0);$sp.Children.Add($tb2)|Out-Null
        $ln=New-Object System.Windows.Shapes.Rectangle;$ln.Height=1;$ln.Fill=NB "#10FFFFFF";$ln.VerticalAlignment="Center";$ln.Width=860;$sp.Children.Add($ln)|Out-Null;$hCards.Children.Add($sp)|Out-Null
        $items=@($cat.Group);for($i=0;$i -lt $items.Count;$i+=3){$grid=New-Object System.Windows.Controls.Grid;$grid.Margin=[System.Windows.Thickness]::new(0,0,0,6)
            for($k=0;$k -lt 3;$k++){$cd=New-Object System.Windows.Controls.ColumnDefinition;$cd.Width=[System.Windows.GridLength]::new(1,[System.Windows.GridUnitType]::Star);$grid.ColumnDefinitions.Add($cd)}
            for($j=$i;$j -lt [math]::Min($i+3,$items.Count);$j++){$gc=$items[$j];$btn=New-Object System.Windows.Controls.Button;$btn.Style=$w.FindResource("GC");$btn.Margin=[System.Windows.Thickness]::new(3,0,3,0);$btn.Height=72;$btn.Tag=$gc.M
                $ig=New-Object System.Windows.Controls.Grid;$ig.Margin=[System.Windows.Thickness]::new(12,8,12,8)
                $c0=New-Object System.Windows.Controls.ColumnDefinition;$c0.Width=[System.Windows.GridLength]::new(42);$c1=New-Object System.Windows.Controls.ColumnDefinition;$c1.Width=[System.Windows.GridLength]::new(1,[System.Windows.GridUnitType]::Star);$ig.ColumnDefinitions.Add($c0);$ig.ColumnDefinitions.Add($c1)
                $ib=New-Object System.Windows.Controls.Border;$ib.Width=34;$ib.Height=34;$ib.CornerRadius=[System.Windows.CornerRadius]::new(10);$ib.Background=NB "#08FFFFFF";$ib.VerticalAlignment="Center"
                $it=New-Object System.Windows.Controls.TextBlock;$it.Text=$gc.I;$it.Foreground=NB $gc.A;$it.FontSize=10;$it.FontWeight="Bold";$it.FontFamily=New-Object System.Windows.Media.FontFamily("Consolas");$it.HorizontalAlignment="Center";$it.VerticalAlignment="Center";$ib.Child=$it
                [System.Windows.Controls.Grid]::SetColumn($ib,0);$ig.Children.Add($ib)|Out-Null
                $ts=New-Object System.Windows.Controls.StackPanel;$ts.Margin=[System.Windows.Thickness]::new(8,0,0,0);$ts.VerticalAlignment="Center"
                $tt=New-Object System.Windows.Controls.TextBlock;$tt.Text=$gc.T;$tt.Foreground=NB "#E0E0E0";$tt.FontSize=11.5;$tt.FontWeight="SemiBold";$ts.Children.Add($tt)|Out-Null
                $td=New-Object System.Windows.Controls.TextBlock;$td.Text=$gc.D;$td.Foreground=NB "#40FFFFFF";$td.FontSize=9;$td.Margin=[System.Windows.Thickness]::new(0,1,0,3);$ts.Children.Add($td)|Out-Null
                $dfc=switch($gc.Df){"Easy"{"#00B894"}"Medium"{"#FDCB6E"}"Hard"{"#E84855"}};$dfb=switch($gc.Df){"Easy"{"#10008040"}"Medium"{"#10806020"}"Hard"{"#10803020"}}
                $db=New-Object System.Windows.Controls.Border;$db.Background=NB $dfb;$db.CornerRadius=[System.Windows.CornerRadius]::new(5);$db.Padding=[System.Windows.Thickness]::new(6,1,6,1);$db.HorizontalAlignment="Left"
                $dtb=New-Object System.Windows.Controls.TextBlock;$dtb.Text=$gc.Df;$dtb.Foreground=NB $dfc;$dtb.FontSize=8;$dtb.FontWeight="Bold";$db.Child=$dtb;$ts.Children.Add($db)|Out-Null
                [System.Windows.Controls.Grid]::SetColumn($ts,1);$ig.Children.Add($ts)|Out-Null;$btn.Content=$ig
                $btn.Add_Click({Launch $this.Tag});[System.Windows.Controls.Grid]::SetColumn($btn,$j-$i);$grid.Children.Add($btn)|Out-Null}
            $hCards.Children.Add($grid)|Out-Null}}}
BH $null
$cAll.Add_Click({BH $null});$cBrn.Add_Click({BH "Brain"});$cVed.Add_Click({BH "Vedic"});$cTes.Add_Click({BH "Teaser"});$cSud.Add_Click({BH "Sudoku"})

# Numpad
foreach($t in @("7","8","9","4","5","6","1","2","3","+/-","0","DEL")){$nb=New-Object System.Windows.Controls.Button;$nb.Content=$t;$nb.Height=42;$nb.Margin=[System.Windows.Thickness]::new(2.5);$nb.Tag=$t;$nb.Style=$w.FindResource("NP");if($t -eq "DEL"){$nb.Foreground=NB "#E84855"}elseif($t -eq "+/-"){$nb.Foreground=NB "#FDCB6E"};$nb.Add_Click({if(-not $script:gameActive){return};switch($this.Tag){"DEL"{if($aIn.Text.Length -gt 0){$aIn.Text=$aIn.Text.Substring(0,$aIn.Text.Length-1)}}"+/-"{if($aIn.Text.StartsWith("-")){$aIn.Text=$aIn.Text.Substring(1)}else{$aIn.Text="-"+$aIn.Text}}default{$aIn.Text+=$this.Tag}};$aIn.Focus();$aIn.CaretIndex=$aIn.Text.Length});$npG.Children.Add($nb)|Out-Null}

# ============================================================
# SCHULTE TABLE
# ============================================================
function StartSchulte($size){$script:currentGame="Schulte$size";$script:gameActive=$true;$script:elapsed=0;$script:schulteSize=$size;$script:schulteNext=1;$script:score=0
    $total=$size*$size;$gTl.Text="SCHULTE ${size}x${size}";$gSc.Text="0";$gTm.Text="0:00";$gStL.Text="NEXT";$gSt.Text="1";$gFb.Text=""
    $gInstr.Text="Eyes on CENTER. Click 1 to $total in order.";$gGrid.Children.Clear();$gGrid.Rows=$size;$gGrid.Columns=$size
    $nums=1..$total;$rng=New-Object System.Random;$arr=[System.Collections.ArrayList]::new($nums)
    for($i=$arr.Count-1;$i -gt 0;$i--){$j=$rng.Next(0,$i+1);$tmp=$arr[$i];$arr[$i]=$arr[$j];$arr[$j]=$tmp}
    foreach($n in $arr){$btn=New-Object System.Windows.Controls.Button;$btn.Content=$n.ToString();$btn.Style=$w.FindResource("Cell");$btn.Margin=[System.Windows.Thickness]::new(3);$btn.Tag=$n;$btn.FontSize=if($size -le 5){22}else{16}
        $btn.Add_Click({if(-not $script:gameActive){return};$num=[int]$this.Tag
            if($num -eq $script:schulteNext){$this.IsEnabled=$false;$this.Foreground=NB "#00B894";$this.Opacity=0.4;$script:schulteNext++;$script:score+=10;$gSc.Text=$script:score;$gSt.Text=$script:schulteNext.ToString()
                $total2=$script:schulteSize*$script:schulteSize;if($script:schulteNext -gt $total2){$script:gameActive=$false;$script:gt.Stop();$script:gamesPlayed++;$gFb.Text="Done! Time: $($gTm.Text)";$gSt.Text="OK";if($script:score -gt $script:highScore){$script:highScore=$script:score};RH}
            }else{$gFb.Text="Need $($script:schulteNext)";$gFb.Foreground=NB "#E84855"}})
        $gGrid.Children.Add($btn)|Out-Null}
    Go "Grid";$script:gt.Start()}

# ============================================================
# STROOP - FIXED: Separate screen with word ABOVE buttons
# ============================================================
$script:stroopWrong = 0

function StartStroop {
    $script:currentGame = "Stroop"; $script:gameActive = $true; $script:elapsed = 0
    $script:score = 0; $script:correctQ = 0; $script:stroopWrong = 0; $script:stroopRound = 0
    $stSc.Text = "0"; $stWr.Text = "0"; $stRd.Text = "0/20"; $stTm.Text = "0:00"; $stFb.Text = ""
    NextStroop
    Go "Stroop"; $script:gt.Start()
}

function NextStroop {
    $script:stroopRound++
    if ($script:stroopRound -gt 20) {
        $script:gameActive = $false; $script:gt.Stop(); $script:gamesPlayed++
        $stFb.Text = "Done! $($script:correctQ)/20 correct in $($stTm.Text)"
        $stFb.Foreground = NB "#00B894"
        if ($script:score -gt $script:highScore) { $script:highScore = $script:score }
        RH; return
    }
    $stRd.Text = "$($script:stroopRound)/20"

    # Color definitions
    $colors = @(
        @{N="RED";    H="#E84855"},
        @{N="GREEN";  H="#00B894"},
        @{N="BLUE";   H="#60CDFF"},
        @{N="YELLOW"; H="#FDCB6E"},
        @{N="PINK";   H="#FD79A8"},
        @{N="PURPLE"; H="#A29BFE"}
    )

    # Pick word and DIFFERENT ink color
    $wordIdx = Get-Random -Minimum 0 -Maximum $colors.Count
    $inkIdx = $wordIdx
    while ($inkIdx -eq $wordIdx) { $inkIdx = Get-Random -Minimum 0 -Maximum $colors.Count }

    $script:stroopCorrectColor = $colors[$inkIdx].N

    # Set the big word
    $stWord.Text = $colors[$wordIdx].N
    $stWord.Foreground = NB $colors[$inkIdx].H

    # Build 6 answer buttons
    $stBtns.Children.Clear()

    # Shuffle colors for button order
    $shuffled = $colors | Get-Random -Count $colors.Count

    foreach ($clr in $shuffled) {
        $btn = New-Object System.Windows.Controls.Button
        $btn.Style = $w.FindResource("StroopBtn")
        $btn.Content = $clr.N
        $btn.Foreground = NB $clr.H
        $btn.Tag = $clr.N
        $btn.Margin = [System.Windows.Thickness]::new(4)
        $btn.Height = 58

        $btn.Add_Click({
            if (-not $script:gameActive) { return }
            $clicked = $this.Tag
            if ($clicked -eq $script:stroopCorrectColor) {
                $script:correctQ++; $script:score += 30
                $stSc.Text = $script:correctQ.ToString()
                $stFb.Text = "Correct!"; $stFb.Foreground = NB "#00B894"
            } else {
                $script:stroopWrong++
                $stWr.Text = $script:stroopWrong.ToString()
                $stFb.Text = "Wrong! Was: $($script:stroopCorrectColor)"; $stFb.Foreground = NB "#E84855"
            }
            NextStroop
        })
        $stBtns.Children.Add($btn) | Out-Null
    }
}

$stBk.Add_Click({ $script:gameActive = $false; $script:gt.Stop(); Go "Home" })

# ============================================================
# SPEED GRID
# ============================================================
function StartSpeedGrid{$script:currentGame="SpeedGrid";$script:gameActive=$true;$script:elapsed=0;$script:speedHits=0;$script:score=0
    $gTl.Text="SPEED GRID";$gSc.Text="0";$gTm.Text="0:00";$gStL.Text="HITS";$gSt.Text="0";$gFb.Text=""
    $gInstr.Text="Tap the HIGHLIGHTED cell! 30 rounds.";$gGrid.Children.Clear();$gGrid.Rows=4;$gGrid.Columns=4
    for($i=0;$i -lt 16;$i++){$btn=New-Object System.Windows.Controls.Button;$btn.Style=$w.FindResource("Cell");$btn.Content="";$btn.Tag=$i;$btn.Margin=[System.Windows.Thickness]::new(3)
        $btn.Add_Click({if(-not $script:gameActive){return};$idx=[int]$this.Tag
            if($idx -eq $script:speedTarget){$script:speedHits++;$script:score+=15;$gSc.Text=$script:score;$gSt.Text=$script:speedHits;$gFb.Text="";$gFb.Foreground=NB "#00B894"
                if($script:speedHits -ge 30){$script:gameActive=$false;$script:gt.Stop();$script:gamesPlayed++;$gFb.Text="Done! $($gTm.Text)";if($script:score -gt $script:highScore){$script:highScore=$script:score};RH}
                else{HLC}}else{$gFb.Text="Miss!";$gFb.Foreground=NB "#E84855"}})
        $gGrid.Children.Add($btn)|Out-Null}
    HLC;Go "Grid";$script:gt.Start()}

function HLC{foreach($ch in $gGrid.Children){try{$ch.ApplyTemplate();$bg=$ch.Template.FindName("bg",$ch);if($bg){$bg.Background=NB "#08FFFFFF"}}catch{};$ch.Content=""}
    $script:speedTarget=Get-Random -Min 0 -Max 16;$target=$gGrid.Children[$script:speedTarget]
    try{$target.ApplyTemplate();$bg=$target.Template.FindName("bg",$target);if($bg){$bg.Background=NB "#306C5CE7"}}catch{}
    $target.Content="HIT";$target.Foreground=NB "#A29BFE"}

# ============================================================
# N-BACK
# ============================================================
function StartNBack{$script:currentGame="NBack2";$script:gameActive=$true;$script:elapsed=0;$script:nbackHistory=@();$script:nbackStep=0;$script:score=0
    $gTl.Text="N-BACK (N=2)";$gSc.Text="0";$gTm.Text="0:00";$gStL.Text="STEP";$gSt.Text="0";$gFb.Text=""
    $gInstr.Text="Cell flashes. Press MATCH if same position as 2 steps ago.";$gGrid.Children.Clear();$gGrid.Rows=4;$gGrid.Columns=3
    for($i=0;$i -lt 9;$i++){$btn=New-Object System.Windows.Controls.Button;$btn.Style=$w.FindResource("Cell");$btn.Content="";$btn.Tag=$i;$btn.Margin=[System.Windows.Thickness]::new(4);$btn.IsHitTestVisible=$false
        $r2=[math]::Floor($i/3);$c2=$i%3;[System.Windows.Controls.Grid]::SetRow($btn,$r2);[System.Windows.Controls.Grid]::SetColumn($btn,$c2);$gGrid.Children.Add($btn)|Out-Null}
    $mb2=New-Object System.Windows.Controls.Button;$mb2.Style=$w.FindResource("Cell");$mb2.Content="MATCH!";$mb2.FontSize=20;$mb2.Foreground=NB "#A29BFE";$mb2.Margin=[System.Windows.Thickness]::new(4)
    [System.Windows.Controls.Grid]::SetRow($mb2,3);[System.Windows.Controls.Grid]::SetColumnSpan($mb2,3)
    $mb2.Add_Click({if(-not $script:gameActive -or $script:nbackStep -lt $script:nbackN){return}
        $cur=$script:nbackHistory[$script:nbackStep-1];$prev=$script:nbackHistory[$script:nbackStep-1-$script:nbackN]
        if($cur -eq $prev){$script:score+=30;$gSc.Text=$script:score;$gFb.Text="Match!";$gFb.Foreground=NB "#00B894"}
        else{$gFb.Text="No match!";$gFb.Foreground=NB "#E84855"}})
    $gGrid.Children.Add($mb2)|Out-Null
    $script:nbt.Stop();$script:nbt=New-Object System.Windows.Threading.DispatcherTimer;$script:nbt.Interval=[TimeSpan]::FromMilliseconds(2500)
    $script:nbt.Add_Tick({if(-not $script:gameActive){$script:nbt.Stop();return}
        for($i=0;$i -lt 9;$i++){try{$gGrid.Children[$i].ApplyTemplate();$bg=$gGrid.Children[$i].Template.FindName("bg",$gGrid.Children[$i]);if($bg){$bg.Background=NB "#08FFFFFF"}}catch{}}
        $pos=Get-Random -Min 0 -Max 9;$script:nbackHistory+=$pos;$script:nbackStep++;$gSt.Text=$script:nbackStep
        try{$gGrid.Children[$pos].ApplyTemplate();$bg=$gGrid.Children[$pos].Template.FindName("bg",$gGrid.Children[$pos]);if($bg){$bg.Background=NB "#406C5CE7"}}catch{}
        if($script:nbackStep -ge 20){$script:nbt.Stop();$script:gameActive=$false;$script:gt.Stop();$script:gamesPlayed++;$gFb.Text="Done! Score: $($script:score)";if($script:score -gt $script:highScore){$script:highScore=$script:score};RH}})
    $script:nbt.Start();Go "Grid";$script:gt.Start()}

# ============================================================
# SUDOKU (compact)
# ============================================================
$script:sc=New-Object System.Windows.Controls.Button[] 81
for($r=0;$r -lt 9;$r++){$ssGr.RowDefinitions.Add((New-Object System.Windows.Controls.RowDefinition))}
for($c=0;$c -lt 9;$c++){$ssGr.ColumnDefinitions.Add((New-Object System.Windows.Controls.ColumnDefinition))}
for($r=0;$r -lt 9;$r++){for($c=0;$c -lt 9;$c++){$idx=$r*9+$c;$b=New-Object System.Windows.Controls.Button;$b.Style=$w.FindResource("SC");$b.Tag=@{R=$r;C=$c};$ml=if($c%3 -eq 0 -and $c -gt 0){3}else{1};$mt=if($r%3 -eq 0 -and $r -gt 0){3}else{1};$b.Margin=[System.Windows.Thickness]::new($ml,$mt,1,1);$b.Add_Click({$i=$this.Tag;$script:selRow=$i.R;$script:selCol=$i.C;RSG});[System.Windows.Controls.Grid]::SetRow($b,$r);[System.Windows.Controls.Grid]::SetColumn($b,$c);$ssGr.Children.Add($b)|Out-Null;$script:sc[$idx]=$b}}
$script:snb=@()
for($n=1;$n -le 9;$n++){$b=New-Object System.Windows.Controls.Button;$b.Content=$n.ToString();$b.Tag=$n;$b.Style=$w.FindResource("SN");$b.Margin=[System.Windows.Thickness]::new(2.5);$b.Add_Click({if(-not $script:gameActive){return};$num=[int]$this.Tag;if($script:selRow -lt 0){return};$key="$($script:selRow),$($script:selCol)";if($script:sudokuFixed.ContainsKey($key)){return};if($script:noteMode){if(-not $script:sudokuNotes.ContainsKey($key)){$script:sudokuNotes[$key]=@()};if($script:sudokuNotes[$key] -contains $num){$script:sudokuNotes[$key]=@($script:sudokuNotes[$key]|Where-Object{$_ -ne $num})}else{$script:sudokuNotes[$key]+=$num};SC2 $script:selRow $script:selCol 0}else{$script:sudokuNotes.Remove($key);$ov=GC2 $script:selRow $script:selCol;[void]$script:sudokuHistory.Add(@{R=$script:selRow;C=$script:selCol;V=$ov});SC2 $script:selRow $script:selCol $num;$sv=GS2 $script:selRow $script:selCol;if($num -ne $sv){$script:mistakes++;$ssEr.Text="$($script:mistakes)/3";if($script:mistakes -ge 3){$ssEr.Foreground=NB "#E84855";$script:gameActive=$false;$script:gt.Stop();$ssFb.Text="Too many mistakes!";$ssFb.Foreground=NB "#E84855"}elseif($script:mistakes -ge 2){$ssEr.Foreground=NB "#FDCB6E"}}else{RN3 $script:selRow $script:selCol $num}};UR3;RSG;CW3});$ssNm.Children.Add($b)|Out-Null;$script:snb+=$b}

function GS4($D){$g=New-Object 'int[,]' 9,9;function IV($g,$r,$c,$n){for($i=0;$i -lt 9;$i++){if($g[$r,$i]-eq $n -or $g[$i,$c]-eq $n){return $false}};$br=[math]::Floor($r/3)*3;$bc=[math]::Floor($c/3)*3;for($rr=$br;$rr -lt $br+3;$rr++){for($cc=$bc;$cc -lt $bc+3;$cc++){if($g[$rr,$cc]-eq $n){return $false}}};return $true};function FG($g){for($r=0;$r -lt 9;$r++){for($c=0;$c -lt 9;$c++){if($g[$r,$c]-eq 0){$ns=1..9|Get-Random -Count 9;foreach($n in $ns){if(IV $g $r $c $n){$g[$r,$c]=$n;if(FG $g){return $true};$g[$r,$c]=0}};return $false}}};return $true};[void](FG $g);$script:sudokuSolution=New-Object 'int[,]' 9,9;for($r=0;$r -lt 9;$r++){for($c=0;$c -lt 9;$c++){$script:sudokuSolution[$r,$c]=$g[$r,$c]}};$cl=switch($D){"Easy"{Get-Random -Min 42 -Max 48}"Medium"{Get-Random -Min 32 -Max 38}"Hard"{Get-Random -Min 24 -Max 30}};$tr=81-$cl;$ap=[System.Collections.ArrayList]::new();for($r=0;$r -lt 9;$r++){for($c=0;$c -lt 9;$c++){[void]$ap.Add(@($r,$c))}};$rng=New-Object System.Random;for($i=$ap.Count-1;$i -gt 0;$i--){$j=$rng.Next(0,$i+1);$tmp=$ap[$i];$ap[$i]=$ap[$j];$ap[$j]=$tmp};$rm=0;for($ix=0;$ix -lt $ap.Count -and $rm -lt $tr;$ix++){$p=$ap[$ix];$g[$p[0],$p[1]]=0;$rm++};$script:sudokuFixed=@{};for($r=0;$r -lt 9;$r++){for($c=0;$c -lt 9;$c++){if($g[$r,$c]-ne 0){$script:sudokuFixed["$r,$c"]=$true}}};$script:sudokuGrid=$g}
function RSG{$sv2=0;if($script:selRow -ge 0 -and $script:selCol -ge 0){$sv2=GC2 $script:selRow $script:selCol};$sbR=if($script:selRow -ge 0){[math]::Floor($script:selRow/3)*3}else{-1};$sbC=if($script:selCol -ge 0){[math]::Floor($script:selCol/3)*3}else{-1};for($r=0;$r -lt 9;$r++){for($c=0;$c -lt 9;$c++){$idx=$r*9+$c;$btn=$script:sc[$idx];$v=GC2 $r $c;$sol=GS2 $r $c;$k="$r,$c";$fx=$script:sudokuFixed.ContainsKey($k);$sel=($r -eq $script:selRow -and $c -eq $script:selCol);$sR=($r -eq $script:selRow);$sC=($c -eq $script:selCol);$sB=($script:selRow -ge 0 -and [math]::Floor($r/3)*3 -eq $sbR -and [math]::Floor($c/3)*3 -eq $sbC);$sN=($sv2 -ne 0 -and $v -eq $sv2 -and $v -ne 0);$wr=($v -ne 0 -and -not $fx -and $v -ne $sol);$hn=$script:sudokuNotes.ContainsKey($k) -and $script:sudokuNotes[$k].Count -gt 0;if($v -ne 0){$btn.Content=$v.ToString();$btn.FontSize=20;$btn.FontWeight=if($fx){"Bold"}else{"SemiBold"}}elseif($hn){$nt="";for($n=1;$n -le 9;$n++){if($script:sudokuNotes[$k] -contains $n){$nt+="$n"}else{$nt+=" "};if($n%3 -eq 0 -and $n -lt 9){$nt+="`n"}};$btn.Content=$nt;$btn.FontSize=7.5;$btn.FontWeight="Normal"}else{$btn.Content="";$btn.FontSize=20};$bg=$null;try{$btn.ApplyTemplate();$bg=$btn.Template.FindName("bg",$btn)}catch{};if($null -ne $bg){if($sel){$bg.Background=NB "#CC6C5CE7";$btn.Foreground=NB "White";$bg.BorderBrush=NB "#A29BFE";$bg.BorderThickness=[System.Windows.Thickness]::new(1.5)}elseif($wr){$bg.Background=NB "#30E84855";$btn.Foreground=NB "#E84855";$bg.BorderBrush=NB "#0CFFFFFF";$bg.BorderThickness=[System.Windows.Thickness]::new(0.5)}elseif($sN){$bg.Background=NB "#206C5CE7";$btn.Foreground=NB "#A29BFE";$bg.BorderBrush=NB "#0CFFFFFF";$bg.BorderThickness=[System.Windows.Thickness]::new(0.5)}elseif($sR -or $sC -or $sB){$bg.Background=NB "#0CFFFFFF";$bg.BorderBrush=NB "#0CFFFFFF";$bg.BorderThickness=[System.Windows.Thickness]::new(0.5);$btn.Foreground=if($fx){NB "#AAA"}elseif($v -ne 0){NB "#A29BFE"}else{NB "#555"}}else{$bg.Background=if($fx){NB "#12FFFFFF"}else{NB "#08FFFFFF"};$bg.BorderBrush=NB "#08FFFFFF";$bg.BorderThickness=[System.Windows.Thickness]::new(0.5);$btn.Foreground=if($fx){NB "#CCC"}elseif($v -ne 0){NB "#A29BFE"}else{NB "White"}}}}};for($n=1;$n -le 9;$n++){$cnt=0;for($r=0;$r -lt 9;$r++){for($c=0;$c -lt 9;$c++){if((GC2 $r $c)-eq $n){$cnt++}}};$nb2=$script:snb[$n-1];if($cnt -ge 9){$nb2.Foreground=NB "#25FFFFFF";$nb2.IsEnabled=$false}else{$nb2.Foreground=NB "White";$nb2.IsEnabled=$true}}}
function RN3($row,$col,$num){$bR=[math]::Floor($row/3)*3;$bC=[math]::Floor($col/3)*3;for($r=0;$r -lt 9;$r++){for($c=0;$c -lt 9;$c++){if($r -eq $row -or $c -eq $col -or ([math]::Floor($r/3)*3 -eq $bR -and [math]::Floor($c/3)*3 -eq $bC)){$k="$r,$c";if($script:sudokuNotes.ContainsKey($k)){$script:sudokuNotes[$k]=@($script:sudokuNotes[$k]|Where-Object{$_ -ne $num})}}}}}
function UR3{$e=0;for($r=0;$r -lt 9;$r++){for($c=0;$c -lt 9;$c++){if((GC2 $r $c)-eq 0){$e++}}};$ssLf.Text=$e.ToString()}
function CW3{for($r=0;$r -lt 9;$r++){for($c=0;$c -lt 9;$c++){if((GC2 $r $c)-ne(GS2 $r $c)){return}}};$script:gameActive=$false;$script:gt.Stop();$script:gamesPlayed++;$ssFb.Text="Solved!";$ssFb.Foreground=NB "#00B894";foreach($b in $script:sc){try{$b.ApplyTemplate();$bg=$b.Template.FindName("bg",$b);if($bg){$bg.Background=NB "#1500B894"}}catch{}};RH}
function SSud($D){$script:currentGame="Sudoku$D";$script:gameActive=$true;$script:sudokuTime=0;$script:mistakes=0;$script:hintsLeft=3;$script:selRow=-1;$script:selCol=-1;$script:noteMode=$false;$script:sudokuNotes=@{};$script:sudokuHistory=[System.Collections.ArrayList]::new();$ssTm.Text="0:00";$ssEr.Text="0/3";$ssEr.Foreground=NB "White";$ssFb.Text="";$ssNo.Foreground=NB "#AAA";$dc=switch($D){"Easy"{"#00B894"}"Medium"{"#FDCB6E"}"Hard"{"#E84855"}};$sDf.Text=$D.ToUpper();$sDf.Foreground=NB $dc;GS4 $D;UR3;RSG;Go "Sudoku";$script:gt.Start()}
$sBk.Add_Click({$script:gameActive=$false;$script:gt.Stop();Go "Home"})
$ssNo.Add_Click({$script:noteMode=-not $script:noteMode;if($script:noteMode){$ssNo.Foreground=NB "#A29BFE"}else{$ssNo.Foreground=NB "#AAA"}})
$ssEs.Add_Click({if($script:selRow -ge 0){$k="$($script:selRow),$($script:selCol)";if(-not $script:sudokuFixed.ContainsKey($k)){$ov=GC2 $script:selRow $script:selCol;[void]$script:sudokuHistory.Add(@{R=$script:selRow;C=$script:selCol;V=$ov});SC2 $script:selRow $script:selCol 0;$script:sudokuNotes.Remove($k);UR3;RSG}}})
$ssUn.Add_Click({if($script:sudokuHistory.Count -gt 0){$l=$script:sudokuHistory[$script:sudokuHistory.Count-1];SC2 $l.R $l.C $l.V;$script:sudokuHistory.RemoveAt($script:sudokuHistory.Count-1);UR3;RSG}})
$ssHi.Add_Click({if(-not $script:gameActive -or $script:hintsLeft -le 0){return};$em=@();for($r=0;$r -lt 9;$r++){for($c=0;$c -lt 9;$c++){$cv2=GC2 $r $c;$sv2=GS2 $r $c;if($cv2 -eq 0 -or $cv2 -ne $sv2){$em+=,@($r,$c)}}};if($em.Count -gt 0){$pk=$em|Get-Random;$sv3=GS2 $pk[0] $pk[1];SC2 $pk[0] $pk[1] $sv3;$script:sudokuFixed["$($pk[0]),$($pk[1])"]=$true;$script:sudokuNotes.Remove("$($pk[0]),$($pk[1])");$script:hintsLeft--;UR3;RSG;CW3}})
$ssNw.Add_Click({$d=$script:currentGame -replace "Sudoku","";SSud $d})

# ============================================================
# ARITHMETIC ENGINE
# ============================================================
function MkQ{$lv=$script:level;$tPnl.Visibility="Collapsed";$script:puzzleHint="";$script:puzzleSteps=@()
    $gi=$script:allG|Where-Object{$_.M -eq $script:currentGame}|Select-Object -First 1
    if($gi -and $gi.Tr){$tT.Text=$gi.T;$tB.Text=$gi.Tr;$tPnl.Visibility="Visible"}
    switch($script:currentGame){
        "Sand11"{$a=Get-Random -Min 11 -Max(50+$lv*10);$script:answer=$a*11;return "$a x 11 = ?"}
        "Ghost"{$a=Get-Random -Min 91 -Max 99;$b=Get-Random -Min 91 -Max 99;$script:answer=$a*$b;return "$a x $b = ?"}
        "Sparkle"{$tens=Get-Random -Min 1 -Max(6+$lv);$a=$tens*10+5;$script:answer=$a*$a;return "$a x $a = ?"}
        "Last"{$base=if($lv -le 3){1000}else{10000};$a=Get-Random -Min([int]($base/10)) -Max($base-1);$script:answer=$base-$a;return "$base - $a = ?"}
        "VSpeed"{switch(Get-Random -Min 0 -Max 4){0{$a=Get-Random -Min 11 -Max 99;$script:answer=$a*11;return "$a x 11 = ?"}1{$a=Get-Random -Min 91 -Max 99;$b=Get-Random -Min 91 -Max 99;$script:answer=$a*$b;return "$a x $b = ?"}2{$tens=Get-Random -Min 1 -Max 10;$a=$tens*10+5;$script:answer=$a*$a;return "$a x $a = ?"}3{$a=Get-Random -Min 100 -Max 999;$script:answer=1000-$a;return "1000 - $a = ?"}}}
        "WaterQ"{$p=$script:brainTeasers["WaterJug"]|Get-Random;$script:answer=$p.A;$script:puzzleHint=$p.H;$script:puzzleSteps=$p.S;return $p.Q}
        "WeightQ"{$p=$script:brainTeasers["Weight"]|Get-Random;$script:answer=$p.A;$script:puzzleHint=$p.H;$script:puzzleSteps=$p.S;return $p.Q}
        "CoinQ"{$p=$script:brainTeasers["Coin"]|Get-Random;$script:answer=$p.A;$script:puzzleHint=$p.H;$script:puzzleSteps=$p.S;return $p.Q}
        "TrickQ"{$p=$script:brainTeasers["Math"]|Get-Random;$script:answer=$p.A;$script:puzzleHint=$p.H;$script:puzzleSteps=$p.S;return $p.Q}
    }
    $script:answer=0;return "?"
}
$aHint.Add_Click({if($script:puzzleHint){$tT.Text="HINT";$tB.Text=$script:puzzleHint;$tPnl.Visibility="Visible"}})

# ============================================================
# LAUNCH + SUBMIT + END
# ============================================================
function Launch($mode){$script:currentGame=$mode
    if($mode -like "Sudoku*"){$d=$mode -replace "Sudoku","";SSud $d;return}
    if($mode -eq "Schulte5"){StartSchulte 5;return}
    if($mode -eq "Schulte7"){StartSchulte 7;return}
    if($mode -eq "Stroop"){StartStroop;return}
    if($mode -eq "SpeedGrid"){StartSpeedGrid;return}
    if($mode -eq "NBack2"){StartNBack;return}
    # Arithmetic
    $gi=$script:allG|Where-Object{$_.M -eq $mode}|Select-Object -First 1
    $script:score=0;$script:streak=0;$script:level=1;$script:totalQ=0;$script:correctQ=0;$script:qThisLvl=0;$script:gameActive=$true;$script:elapsed=0
    $aTl.Text=$gi.T;$dfc=switch($gi.Df){"Easy"{"#00B894"}"Medium"{"#FDCB6E"}"Hard"{"#E84855"}};$aDf.Text=$gi.Df.ToUpper();$aDf.Foreground=NB $dfc
    $tm=if($gi.Tm){$gi.Tm}elseif($mode -match "Speed|VSpeed"){60}else{30}
    $script:timeLeft=$tm;$aSc.Text="0";$aSk.Text="0";$aTm.Text="$($script:timeLeft)s";$aTm.Foreground=NB "White"
    $aFb.Text="";$aIn.Text="";$tPnl.Visibility="Collapsed";$tBar.Width=1140;$tBar.Background=NB "#6C5CE7"
    $aHint.Visibility=if($mode -match "Q$"){"Visible"}else{"Collapsed"}
    $q=(MkQ);$aQ.Text=$q;$aQ.FontSize=if($mode -match "Q$"){17}else{32}
    Go "Arith";$aIn.Focus();$script:gt.Start()}

function SubA{if(-not $script:gameActive){return};if($aIn.Text.Trim() -eq ""){return};$ua=0;if(-not [double]::TryParse($aIn.Text.Trim(),[ref]$ua)){$aFb.Text="Invalid!";$aFb.Foreground=NB "#E84855";$aIn.Text="";$script:ft.Stop();$script:ft.Start();return}
    $script:totalQ++;$ok=($ua -eq $script:answer)
    if($ok){$script:correctQ++;$script:streak++;$script:qThisLvl++;if($script:streak -gt $script:bestStreak){$script:bestStreak=$script:streak}
        $combo=1;if($script:streak -ge 20){$combo=5}elseif($script:streak -ge 15){$combo=4}elseif($script:streak -ge 10){$combo=3}elseif($script:streak -ge 5){$combo=2}
        $bp=if($script:currentGame -match "Q$"){50}elseif($script:currentGame -match "Speed|VSpeed"){25}else{20}
        $pts=$bp*$combo*$script:level;$script:score+=$pts
        if($script:qThisLvl -ge 5){$script:level++;$script:qThisLvl=0;$aFb.Text="+$pts LEVEL UP!";$aFb.Foreground=NB "#FDCB6E"}
        else{$ex=if($combo -gt 1){"  x$combo"}else{""};$aFb.Text="+$pts$ex";$aFb.Foreground=NB "#00B894"}
        if($script:puzzleSteps.Count -gt 0){$tT.Text="SOLUTION";$tB.Text=($script:puzzleSteps -join "`n");$tPnl.Visibility="Visible"}
    }else{$script:streak=0;$aFb.Text="Answer: $($script:answer)";$aFb.Foreground=NB "#E84855"
        if($script:puzzleSteps.Count -gt 0){$tT.Text="SOLUTION";$tB.Text=($script:puzzleSteps -join "`n");$tPnl.Visibility="Visible"}}
    $aSc.Text=$script:score;$aSk.Text=$script:streak;$aIn.Text="";$aQ.Text=(MkQ);$script:ft.Stop();$script:ft.Start();$aIn.Focus();$aIn.CaretIndex=0}

function EndArith{$script:gameActive=$false;$script:gt.Stop();$script:gamesPlayed++;if($script:score -gt $script:highScore){$script:highScore=$script:score}
    $hi=($script:score -eq $script:highScore -and $script:score -gt 0);$rSc.Text=$script:score;$rHi.Text=if($hi){"HIGH SCORE!"}else{""};RH;Go "Result"}

function RH{$lHP.Text="$($script:gamesPlayed) played";$lHH.Text="Best: $($script:highScore)";$lHS.Text="Streak: $($script:bestStreak)"}

$gBk.Add_Click({$script:gameActive=$false;$script:gt.Stop();$script:nbt.Stop();Go "Home"})
$aBk.Add_Click({$script:gameActive=$false;$script:gt.Stop();Go "Home"})
$aGo.Add_Click({SubA})
$aIn.Add_KeyDown({param($s,$e);if($e.Key -eq "Return"){$e.Handled=$true;SubA}})
$rAg.Add_Click({Launch $script:currentGame});$rMn.Add_Click({Go "Home"})

# Keyboard
$w.Add_KeyDown({param($s,$e)
    if($sS.Visibility -eq "Visible" -and $script:gameActive){$k=$e.Key.ToString()
        if($k -match '^D([1-9])$' -or $k -match '^NumPad([1-9])$'){$num=[int]$Matches[1];if($script:selRow -ge 0){$key="$($script:selRow),$($script:selCol)";if(-not $script:sudokuFixed.ContainsKey($key)){if($script:noteMode){if(-not $script:sudokuNotes.ContainsKey($key)){$script:sudokuNotes[$key]=@()};if($script:sudokuNotes[$key] -contains $num){$script:sudokuNotes[$key]=@($script:sudokuNotes[$key]|Where-Object{$_ -ne $num})}else{$script:sudokuNotes[$key]+=$num};SC2 $script:selRow $script:selCol 0}else{$script:sudokuNotes.Remove($key);$ov=GC2 $script:selRow $script:selCol;[void]$script:sudokuHistory.Add(@{R=$script:selRow;C=$script:selCol;V=$ov});SC2 $script:selRow $script:selCol $num;$sv=GS2 $script:selRow $script:selCol;if($num -ne $sv){$script:mistakes++;$ssEr.Text="$($script:mistakes)/3";if($script:mistakes -ge 3){$ssEr.Foreground=NB "#E84855";$script:gameActive=$false;$script:gt.Stop();$ssFb.Text="Too many mistakes!";$ssFb.Foreground=NB "#E84855"}elseif($script:mistakes -ge 2){$ssEr.Foreground=NB "#FDCB6E"}}else{RN3 $script:selRow $script:selCol $num}};UR3;RSG;CW3}}}
        if($k -eq "Delete" -or $k -eq "Back"){if($script:selRow -ge 0){$key="$($script:selRow),$($script:selCol)";if(-not $script:sudokuFixed.ContainsKey($key)){$ov=GC2 $script:selRow $script:selCol;[void]$script:sudokuHistory.Add(@{R=$script:selRow;C=$script:selCol;V=$ov});SC2 $script:selRow $script:selCol 0;$script:sudokuNotes.Remove($key);UR3;RSG}}}
        if($k -eq "Up" -and $script:selRow -gt 0){$script:selRow--;RSG};if($k -eq "Down" -and $script:selRow -lt 8){$script:selRow++;RSG}
        if($k -eq "Left" -and $script:selCol -gt 0){$script:selCol--;RSG};if($k -eq "Right" -and $script:selCol -lt 8){$script:selCol++;RSG}
        if($k -eq "N"){$script:noteMode=-not $script:noteMode;if($script:noteMode){$ssNo.Foreground=NB "#A29BFE"}else{$ssNo.Foreground=NB "#AAA"}}
        if($k -eq "Z" -and $script:sudokuHistory.Count -gt 0){$l=$script:sudokuHistory[$script:sudokuHistory.Count-1];SC2 $l.R $l.C $l.V;$script:sudokuHistory.RemoveAt($script:sudokuHistory.Count-1);UR3;RSG}
    }
    if($e.Key -eq "Escape"){$script:gameActive=$false;$script:gt.Stop();$script:nbt.Stop();Go "Home"}
})

$w.ShowDialog()|Out-Null
