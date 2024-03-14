{$V-}  { Required for Magic Unit }{ $M StackSize, HeapMin, HeapMax }
{ $M Defaults 16384, 0, 655360 }

{$M 49152, 8192, 655360}

Unit WspCalc;

  Interface

  Uses
    Crt, Dos, WspMagic, WspErr, Global;

{---------------------- Public Functions\Procedures --------------------------}

{    All documentation for the following Functions\Procedures is found in the
   actual Function\Procedure code.                                            }

{-----------------------------------------------------------------------------}

  Procedure Wisp_Calculations (report      : Boolean;
                               displaydata : Integer);

{-----------------------------------------------------------------------------}

  Implementation

{---------------------------- Include Files 1 --------------------------------}

{$I RD_N.PAS }  { Get Report Information. "Magic Screen Code"  (modified)     }

{----------------------------- Function Adjust_Et ----------------------------}

  Function Adjust_Et (et    ,
                      cover : Real) : Real;

  Type
    etarray        = Array [0..8] of Real;

  Var
    etval ,
    p1    ,
    p2    ,
    p3    ,
    p4    ,
    p12   ,
    p34   : Real;
    x     ,
    y     : Integer;
    ettable         : Array [-4..14] of EtArray;

{++++++++++++++++++++++ Nested Procedure Init_Et_Table +++++++++++++++++++++++}

{    This procedure Initializes an array that is needed for calculating the
   Adjusted Et values.                                                        }

{+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++}

  Procedure Init_Et_Table;

    Begin  { Procedure Init_Et_Table }

      ettable[-4, 0] := 0;
      ettable[-4, 1] := 0;
      ettable[-4, 2] := 0;
      ettable[-4, 3] := 0;
      ettable[-4, 4] := 0;
      ettable[-4, 5] := 0;
      ettable[-4, 6] := 0;
      ettable[-4, 7] := 0;
      ettable[-4, 8] := 0;
      ettable[-3, 0] := 0;
      ettable[-3, 1] := 0;
      ettable[-3, 2] := 0;
      ettable[-3, 3] := 0.01;
      ettable[-3, 4] := 0.01;
      ettable[-3, 5] := 0.01;
      ettable[-3, 6] := 0.02;
      ettable[-3, 7] := 0.02;
      ettable[-3, 8] := 0.02;
      ettable[-2, 0] := 0;
      ettable[-2, 1] := 0;
      ettable[-2, 2] := 0.01;
      ettable[-2, 3] := 0.02;
      ettable[-2, 4] := 0.03;
      ettable[-2, 5] := 0.03;
      ettable[-2, 6] := 0.04;
      ettable[-2, 7] := 0.04;
      ettable[-2, 8] := 0.04;
      ettable[-1, 0] := 0;
      ettable[-1, 1] := 0.01;
      ettable[-1, 2] := 0.02;
      ettable[-1, 3] := 0.03;
      ettable[-1, 4] := 0.04;
      ettable[-1, 5] := 0.05;
      ettable[-1, 6] := 0.05;
      ettable[-1, 7] := 0.06;
      ettable[-1, 8] := 0.06;
      ettable[ 0, 0] := 0;
      ettable[ 0, 1] := 0.02;
      ettable[ 0, 2] := 0.03;
      ettable[ 0, 3] := 0.04;
      ettable[ 0, 4] := 0.05;
      ettable[ 0, 5] := 0.06;
      ettable[ 0, 6] := 0.07;
      ettable[ 0, 7] := 0.08;
      ettable[ 0, 8] := 0.08;
      ettable[ 1, 0] := 0;
      ettable[ 1, 1] := 0.02;
      ettable[ 1, 2] := 0.04;
      ettable[ 1, 3] := 0.05;
      ettable[ 1, 4] := 0.07;
      ettable[ 1, 5] := 0.08;
      ettable[ 1, 6] := 0.09;
      ettable[ 1, 7] := 0.10;
      ettable[ 1, 8] := 0.10;
      ettable[ 2, 0] := 0;
      ettable[ 2, 1] := 0.03;
      ettable[ 2, 2] := 0.05;
      ettable[ 2, 3] := 0.06;
      ettable[ 2, 4] := 0.08;
      ettable[ 2, 5] := 0.09;
      ettable[ 2, 6] := 0.11;
      ettable[ 2, 7] := 0.11;
      ettable[ 2, 8] := 0.12;
      ettable[ 3, 0] := 0;
      ettable[ 3, 1] := 0.03;
      ettable[ 3, 2] := 0.05;
      ettable[ 3, 3] := 0.07;
      ettable[ 3, 4] := 0.09;
      ettable[ 3, 5] := 0.11;
      ettable[ 3, 6] := 0.12;
      ettable[ 3, 7] := 0.13;
      ettable[ 3, 8] := 0.14;
      ettable[ 4, 0] := 0.01;
      ettable[ 4, 1] := 0.04;
      ettable[ 4, 2] := 0.06;
      ettable[ 4, 3] := 0.08;
      ettable[ 4, 4] := 0.11;
      ettable[ 4, 5] := 0.13;
      ettable[ 4, 6] := 0.14;
      ettable[ 4, 7] := 0.15;
      ettable[ 4, 8] := 0.16;
      ettable[ 5, 0] := 0.01;
      ettable[ 5, 1] := 0.04;
      ettable[ 5, 2] := 0.07;
      ettable[ 5, 3] := 0.09;
      ettable[ 5, 4] := 0.12;
      ettable[ 5, 5] := 0.14;
      ettable[ 5, 6] := 0.16;
      ettable[ 5, 7] := 0.17;
      ettable[ 5, 8] := 0.18;
      ettable[ 6, 0] := 0.01;
      ettable[ 6, 1] := 0.05;
      ettable[ 6, 2] := 0.08;
      ettable[ 6, 3] := 0.11;
      ettable[ 6, 4] := 0.13;
      ettable[ 6, 5] := 0.16;
      ettable[ 6, 6] := 0.18;
      ettable[ 6, 7] := 0.19;
      ettable[ 6, 8] := 0.20;
      ettable[ 7, 0] := 0.01;
      ettable[ 7, 1] := 0.05;
      ettable[ 7, 2] := 0.08;
      ettable[ 7, 3] := 0.12;
      ettable[ 7, 4] := 0.15;
      ettable[ 7, 5] := 0.17;
      ettable[ 7, 6] := 0.19;
      ettable[ 7, 7] := 0.21;
      ettable[ 7, 8] := 0.22;
      ettable[ 8, 0] := 0.01;
      ettable[ 8, 1] := 0.06;
      ettable[ 8, 2] := 0.09;
      ettable[ 8, 3] := 0.13;
      ettable[ 8, 4] := 0.16;
      ettable[ 8, 5] := 0.19;
      ettable[ 8, 6] := 0.21;
      ettable[ 8, 7] := 0.23;
      ettable[ 8, 8] := 0.24;
      ettable[ 9, 0] := 0.01;
      ettable[ 9, 1] := 0.06;
      ettable[ 9, 2] := 0.10;
      ettable[ 9, 3] := 0.14;
      ettable[ 9, 4] := 0.17;
      ettable[ 9, 5] := 0.20;
      ettable[ 9, 6] := 0.23;
      ettable[ 9, 7] := 0.25;
      ettable[ 9, 8] := 0.26;
      ettable[10, 0] := 0.01;
      ettable[10, 1] := 0.06;
      ettable[10, 2] := 0.11;
      ettable[10, 3] := 0.15;
      ettable[10, 4] := 0.19;
      ettable[10, 5] := 0.22;
      ettable[10, 6] := 0.25;
      ettable[10, 7] := 0.27;
      ettable[10, 8] := 0.28;
      ettable[11, 0] := 0.01;
      ettable[11, 1] := 0.07;
      ettable[11, 2] := 0.12;
      ettable[11, 3] := 0.16;
      ettable[11, 4] := 0.20;
      ettable[11, 5] := 0.23;
      ettable[11, 6] := 0.26;
      ettable[11, 7] := 0.28;
      ettable[11, 8] := 0.30;
      ettable[12, 0] := 0.02;
      ettable[12, 1] := 0.07;
      ettable[12, 2] := 0.12;
      ettable[12, 3] := 0.17;
      ettable[12, 4] := 0.21;
      ettable[12, 5] := 0.25;
      ettable[12, 6] := 0.28;
      ettable[12, 7] := 0.30;
      ettable[12, 8] := 0.32;
      ettable[13, 0] := 0.02;
      ettable[13, 1] := 0.08;
      ettable[13, 2] := 0.13;
      ettable[13, 3] := 0.18;
      ettable[13, 4] := 0.23;
      ettable[13, 5] := 0.26;
      ettable[13, 6] := 0.30;
      ettable[13, 7] := 0.32;
      ettable[13, 8] := 0.34;
      ettable[14, 0] := 0.02;
      ettable[14, 1] := 0.08;
      ettable[14, 2] := 0.14;
      ettable[14, 3] := 0.19;
      ettable[14, 4] := 0.24;
      ettable[14, 5] := 0.28;
      ettable[14, 6] := 0.32;
      ettable[14, 7] := 0.34;
      ettable[14, 8] := 0.36

    End;  { Procedure Init_Et_Table }

{+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++}

  Begin  { Function Adjust_Et }

    if Defaults.UsePctCover = 1 then
      etval := et * cover
    else
      begin

        Init_Et_Table;

        if cover < 80 then
          begin
            y := trunc (cover / 10);
            x := trunc (et * 100 / 2 - 4);

            if x < -4 then
              x := -4;           { changed for updated table; was: if x < 0 ...   }

            if x > 14 then
              x := 14;

            p1 := ettable[x, y];
            p2 := ettable[x, y + 1];

            if x = 14 then
              begin
                p3 := et;
                p4 := et
              end
            else
              begin
                p3 := ettable[x + 1, y];
                p4 := ettable[x + 1, y + 1]
              end;

            p12 := p1 + (p2 - p1) * ((cover - 10 * y) / 10);
            p34 := p3 + (p4 - p3) * ((cover - 10 * y) / 10);
            etval := p12 + (p34 - p12) * ((et * 100 - ((x + 4) *2)) / 2)
          end   { if }
        else
          etval := et;

        etval := Abs (etval);

        if etval > et then
          etval := et
      end;

    Adjust_Et := etval

  End;  { Function Adjust_Et }

{------------------------ Procedure Wisp_Calculations ------------------------}

Procedure Wisp_Calculations (report      : Boolean;
                             displaydata : Integer);

  Var
    head1       ,
    head2       ,
    foot        : String80;
    tempname    : String8;
    beginday    ,
    endday      : String4;
    outfile     : Text;
    jbeginday   ,
    jendday     ,
    fieldorder  ,
    exit        ,
    etcount     ,
    index       ,
    jndex       ,
    index2      : Integer;
    cumadbal    ,
    adbal       ,
    adleft      ,
    adjustedet  ,
    weekset     ,
    todayscover : Real;

  Begin  { Procedure Wisp_Calculations }

    fieldorder := 1;
    tempname   := 'Output';
    beginday   := General.WispStartDay;
    endday     := WispLastDay;

    if Defaults.UsePctCover = 0 then
      CoverPrompt := '% Cover'
    else
      CoverPrompt := 'Crop Coef';

    if displaydata = 3 then
      exit := 3
    else
      exit := 2;

    if report then
      Get_Report_Info (displaydata    ,  { My addition }
                       beginday       ,  { 1 }
                       endday         ,  { 2 }
                       tempname       ,  { 3 }
                       fieldorder     ,  { Valid range: 1..3  }
                       exit           ,  { Exit_Order }
                       _Form_Modified ,
                       4              ,  { Row Max:   }
                       15             ); { Col Max:   }

    if (not (_Function_To_Do in [_Escape, _Abort])) or
       (not report)                                 then
      begin

        Working_Msg;

        WispBeginDay := Julian_Date (General.WispStartDay);
        WispEndDay   := Julian_Date (WispLastDay);

        jbeginday := Julian_Date (beginday);
        jendday   := Julian_Date (endday);

        if (WispEndDay - 6) >= WispBeginDay then
          WispBeginWeek := WispEndDay - 6
        else
          WispBeginWeek := WispBeginDay;

        WispEndWeek := WispEndDay;

        for index := 1 to ONEWEEK do
          begin
            Wisp[index].Date           := '';
            Wisp[index].AdjustedEt     := _Uninitialized_Real;
            Wisp[index].AdBal          := _Uninitialized_Real;
            Wisp[index].AdLeft         := _Uninitialized_Real;
          end;

        if WispEndWeek < (YEAR365 + Leap_Year - 1) then
          begin
            Project1Date := Calendar_Date (WispEndWeek + 1);
            Project2Date := Calendar_Date (WispEndWeek + 2)
          end
        else
          if WispEndWeek = (YEAR365 + Leap_Year - 1) then
            begin
              Project1Date := Calendar_Date (WispEndWeek + 1);
              Project2Date := Calendar_Date (1)
            end
          else
            if WispEndWeek = (YEAR365 + Leap_Year) then
              begin
                Project1Date := Calendar_Date (1);
                Project2Date := Calendar_Date (2)
              end;

        if Defaults.UsePctCover = 0 then
          begin
            head1 := '  Date    Rain   Irrig    ET   Cover  Adj.ET AD BAL AD Left  Proj. AD BAL';
            head2 := '         (inch)  (inch) (inch)  (%)   (inch) (inch)   (%)    24 Hr  48 Hr'
          end
        else
          begin
            head1 := '  Date    Rain   Irrig    ET    Crop  Adj.ET AD BAL AD Left  Proj. AD BAL';
            head2 := '         (inch)  (inch) (inch)  Coef  (inch) (inch)   (%)    24 Hr  48 Hr'
          end;

        foot  := concat ('                <F1> <Home> <End> PgUp/PgDn ',
                         chr (24), chr (25), ' <Esc>');

        if report then
          begin
            assign (outfile, WISPDAYDATA);
            rewrite (outfile)
          end;

        TotalRainFall   := 0;
        TotalIrrigation := 0;
        TotalEt         := 0;
        TotalAdjEt      := 0;
        weekset         := 0;
        etcount         := 0;
        index2          := 0;
        Project1AdBal   := _Uninitialized_Real;
        Project2AdBal   := _Uninitialized_Real;
        cumadbal        := Defaults.InitialAD;

        for index := WispBeginDay to WispEndDay do
          with InputForYear[index] do
            begin
              todayscover := PctCover;

              if todayscover > 80 then
                todayscover := 80;

              adjustedet      := Adjust_Et (Et_Est, todayscover);
              adbal           := RainFall + Irrigation - adjustedet;
              cumadbal        := cumadbal + adbal;
              adleft          :=
                ((Defaults.ADValue + cumadbal) / Defaults.ADValue) * 100 - 100;
              TotalRainfall   := TotalRainfall + RainFall;
              TotalIrrigation := TotalIrrigation + Irrigation;
              TotalEt         := TotalEt + Et_Est;
              TotalAdjEt      := TotalAdjEt + adjustedet;

              if cumadbal > Defaults.ADValue then
                cumadbal := Defaults.ADValue
              else
                if cumadbal < 0 then
                  cumadbal := 0;

              if report then
                begin

                  jndex   := index;
                  etcount := 0;
                  weekset := 0;

                  repeat
                    with InputForYear[jndex] do
                      begin
                        if Rainfall = 0 then
                          begin
                            etcount := etcount + 1;

                            if PctCover > 80 then
                              todayscover := 80
                            else
                              todayscover := PctCover;

                            weekset := weekset + Adjust_Et (Et_Est, todayscover)
                          end;

                        jndex := jndex - 1
                      end;
                  until (etcount = 4) or (index < WispBeginDay);

                  if etcount = 4 then
                    begin
                      Project1AdBal := cumadbal - (weekset / etcount);
                      Project2AdBal := cumadbal - 2 * (weekset / etcount)
                    end
                  else
                    begin
                      Project1AdBal := 0;
                      Project2AdBal := 0
                    end;

                  if Integer_In (Index, jbeginday, jendday) then
                    if Defaults.UsePctCover = 0 then
                      writeln (outfile, ' '      ,
                              Word_Date(index)  ,
                              RainFall:8:2      ,
                              Irrigation:8:2    ,
                              Et_Est:6:2        ,
                              PctCover:6:0      ,
                              '%'               ,
                              adjustedet:7:2    ,
                              cumadbal:7:2      ,
                              adleft:7:0        ,
                              '%'               ,
                              Project1AdBal:8:2 ,
                              Project2AdBal:7:2 )
                    else
                      writeln (outfile, ' '      ,
                              Word_Date(index)  ,
                              RainFall:8:2      ,
                              Irrigation:8:2    ,
                              Et_Est:6:2        ,
                              PctCover:6:0      ,
                              adjustedet:7:2    ,
                              cumadbal:8:2      ,
                              adleft:7:0        ,
                              '%'               ,
                              Project1AdBal:8:2 ,
                              Project2AdBal:7:2 )
                end;

              if WispEndDay - index <= 6 then
                begin
                  index2 := index2 + 1;
                  Wisp[index2].Date       := Calendar_Date (index);
                  Wisp[index2].AdjustedET := adjustedet;
                  Wisp[index2].AdBal      := cumadbal;
                  Wisp[index2].AdLeft     := adleft
                end  { If }

            end;  { For Loop }

        index   := WispEndDay;
        weekset := 0;
        etcount := 0;

        repeat
          with InputForYear[index] do
            begin
              if Rainfall = 0 then
                begin
                  etcount := etcount + 1;

                  if PctCover > 80 then
                    todayscover := 80
                  else
                    todayscover := PctCover;

                  weekset := weekset + Adjust_Et (Et_Est, todayscover)
                end;

              index := index - 1
            end;
        until (etcount = 4) or (index < WispBeginDay);

        if etcount = 4 then
          begin
            Project1AdBal := cumadbal - (weekset / etcount);
            Project2AdBal := cumadbal - 2 * (weekset / etcount)
          end
        else
          if TimesDone <> 0 then
            begin
              GotoXY (25, 12);
              _Message :=
                'Enter 4 non-rain days of data for "Projected AD BAL."';
              Display_Message (_Flash_Msg)
            end;

        if report then
          begin
            writeln (outfile, ' ---------------------------------------------',
                              '---------------------------');
            writeln (outfile, ' Totals'           ,
                              TotalRainFall:8:2    ,
                              TotalIrrigation:8:2  ,
                              TotalEt:6:2          ,
                              TotalAdjEt:14:2      );
            writeln (outfile, ' =============================================',
                              '===========================');

            close (outfile)
          end;

        Inc (TimesDone);

        case displaydata of
          1 : Scroller (WISPDAYDATA ,
                        3           ,
                        3           ,
                        6           ,
                        78          ,
                        21          ,
                        white       ,
                        black       ,
                        white       ,
                        yellow      ,
                        yellow      ,
                        head1       ,
                        head2       ,
                        foot        );

          2 : PD_Output (''          ,
                         WISPDAYDATA ,
                         head1       ,
                         head2       ,
                         TRUE        );

          3 : Begin

                if tempname <> '' then
                  PD_Output (concat (tempname, FILEEXT) ,
                             WISPDAYDATA                ,
                             head1                      ,
                             head2                      ,
                             FALSE                      )
              End

        end;  { Case }

        if File_Exists (WISPDAYDATA) then
          begin
            assign (outfile, WISPDAYDATA);
            erase (outfile)
          end

      end  { If not [_Escape, _Abort] }

  End;  { Procedure Wisp_Calculations }

  End. { Main Unit }
