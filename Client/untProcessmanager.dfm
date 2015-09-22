object Form4: TForm4
  Left = 0
  Top = 0
  Caption = 'Form4'
  ClientHeight = 534
  ClientWidth = 746
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
    Width = 746
    Height = 534
    Align = alClient
    Columns = <
      item
        AutoSize = True
        Caption = 'Processname'
        MaxWidth = 140
        MinWidth = 140
      end
      item
        AutoSize = True
        Caption = 'Path'
      end
      item
        AutoSize = True
        Caption = 'PID'
        MaxWidth = 50
        MinWidth = 50
      end
      item
        AutoSize = True
        Caption = 'Memory'
        MaxWidth = 70
        MinWidth = 70
      end
      item
        AutoSize = True
        Caption = 'Threads'
        MaxWidth = 60
        MinWidth = 60
      end>
    GridLines = True
    ReadOnly = True
    RowSelect = True
    TabOrder = 0
    ViewStyle = vsReport
    ExplicitWidth = 685
    ExplicitHeight = 526
  end
  object PopupMenu1: TPopupMenu
    Left = 384
    Top = 200
    object Refresh1: TMenuItem
      Caption = 'Refresh'
    end
  end
end
