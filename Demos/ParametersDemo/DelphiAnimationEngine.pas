unit DelphiAnimationEngine;

{ Setup:
    Add the "DelphiAnimationEngine" to your project, in your main TForm, create
    a TTimer, set the Interval to 8ms (you can change this if necessary), then
    in the TTimer's OnTimer event, add the line "AnimationTimer"
    The event AnimationTimer will run every 8ms (or whatever your interval is)
    and update the Top, Left, Width and Height values of any controls being
    animated as needed

  Notes:
    DelphiFixes is a requirement for this file and can be downloaded at:
      https://github.com/BhavanBaijnath/DelphiFixes

    This project was built using Delphi 2010, while it seems to be working fine
    on Delphi 12, I did notice and issue with accuracy of animations if the
    TForm's "Scaled" property is set to True. I'm not very experienced with
    Delphi 12, but it seems this can be fixed by multiplying animation values by
    TForm.FScaleFactor, or setting the "Scaled" property to False

  References:
    I used the website below for the formulas to calculate the different easing
    types. These formula were written in TypeScript so I did modify them
    slightly as needed to work with the way I designed this animation system.
      https://easings.net

    I was having issues with multiple animations running simultanesouly on the
    same control so I asked ChatGPT for potential solutions.
    The issue was mainly occuring with buttons for hover animations. If a the
    cursor moved over the button too fast and the up animation doesn't finish,
    the down animation would overwrite this and the button would not return to
    it's correct starting position. This issue was resolved by using an array of
    animations for each control, then when all animations for that specific
    control are run, the final Top, Left, Width and Height values will be
    outputted. This works fine for linear animations, but became an issue with
    the other easing types. With the other easing types you're basically
    guaranteed to have decimals since they are smooth curves. This meant that
    rounding off would cause accuracy issues since the rounding error would
    build up each time the animation is run, which is every 8ms and could
    significantly affect its final value. To fix this, I basically created a
    temporary variable for Top, Left, Width and Height as type Real, which fixed
    the accuracy issues. These real numbers are adjusted as the animations run
    and the rounded off value is outputted since Delphi uses integers for these
    properties.
      https://chatgpt.com/share/676b292a-0fec-8008-8a5d-f2ea5c2ad705 }

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, Math, DelphiFixes, DateUtils, ExtCtrls,
  Grids, StdCtrls, ComCtrls;

const
  MaxAnimationControls = 200;
  // ^^^ The maximum number of controls that can be animated simultaneously
  MaxAnimations = 50;
  // ^^^ The maximum number of animations per control that can happen simultaneously

type

  TAnimationType = (atLinear, atEaseInSine, atEaseInQuad, atEaseInCubic,
    atEaseInQuart, atEaseInQuint, atEaseInExpo, atEaseInCirc, atEaseInBack,
    atEaseInElastic, atEaseOutSine, atEaseOutQuad, atEaseOutCubic,
    atEaseOutQuart, atEaseOutQuint, atEaseOutExpo, atEaseOutCirc, atEaseOutBack,
    atEaseOutElastic, atEaseInOutSine, atEaseInOutQuad, atEaseInOutCubic,
    atEaseInOutQuart, atEaseInOutQuint, atEaseInOutExpo, atEaseInOutCirc,
    atEaseInOutBack, atEaseInOutElastic);
  TAnimationProperty = (apLeft, apTop, apWidth, apHeight);

  TAnimation = class
  private
    FAnimationType: TAnimationType;
    FAnimationProperty: TAnimationProperty;
    FTime, FMovement: Integer;
    FStartTime: TTime;
    FRemainder, FPreviousCalc: Real;
  public
    constructor Create(AAnimationType: TAnimationType;
      AAnimationProperty: TAnimationProperty; ATime: Integer;
      AMovement: Integer; ADelay: Integer = 0);
  end;

  TAnimationControl = class
  private
    FControl: TControl;
    FLeft, FTop, FWidth, FHeight: Real;
    FStartScrollPos: Integer;
    FLeftBool, FTopBool, FWidthBool, FHeightBool: Boolean;
    FAnimations: Array [1 .. MaxAnimations] of TAnimation;
  public
    constructor Create(AControl: TControl);
  end;

var
  arrAnimationControls: Array [1 .. MaxAnimationControls] of TAnimationControl;

procedure AnimateControl(Control: TControl; AnimationType: TAnimationType;
  AnimationProperty: TAnimationProperty; Time: Integer; Movement: Integer;
  Delay: Integer = 0);
procedure AnimationTimer;

// Movement Functions
function Linear(iMovement, iX, iTime: Integer): Real;

// Ease In Functions
function EaseInSine(iMovement, iX, iTime: Integer): Real;
function EaseInQuad(iMovement, iX, iTime: Integer): Real;
function EaseInCubic(iMovement, iX, iTime: Integer): Real;
function EaseInQuart(iMovement, iX, iTime: Integer): Real;
function EaseInQuint(iMovement, iX, iTime: Integer): Real;
function EaseInExpo(iMovement, iX, iTime: Integer): Real;
function EaseInCirc(iMovement, iX, iTime: Integer): Real;
function EaseInBack(iMovement, iX, iTime: Integer): Real;
function EaseInElastic(iMovement, iX, iTime: Integer): Real;

// Ease Out Functions
function EaseOutSine(iMovement, iX, iTime: Integer): Real;
function EaseOutQuad(iMovement, iX, iTime: Integer): Real;
function EaseOutCubic(iMovement, iX, iTime: Integer): Real;
function EaseOutQuart(iMovement, iX, iTime: Integer): Real;
function EaseOutQuint(iMovement, iX, iTime: Integer): Real;
function EaseOutExpo(iMovement, iX, iTime: Integer): Real;
function EaseOutCirc(iMovement, iX, iTime: Integer): Real;
function EaseOutBack(iMovement, iX, iTime: Integer): Real;
function EaseOutElastic(iMovement, iX, iTime: Integer): Real;

// Ease In Out Functions
function EaseInOutSine(iMovement, iX, iTime: Integer): Real;
function EaseInOutQuad(iMovement, iX, iTime: Integer): Real;
function EaseInOutCubic(iMovement, iX, iTime: Integer): Real;
function EaseInOutQuart(iMovement, iX, iTime: Integer): Real;
function EaseInOutQuint(iMovement, iX, iTime: Integer): Real;
function EaseInOutExpo(iMovement, iX, iTime: Integer): Real;
function EaseInOutCirc(iMovement, iX, iTime: Integer): Real;
function EaseInOutBack(iMovement, iX, iTime: Integer): Real;
function EaseInOutElastic(iMovement, iX, iTime: Integer): Real;

implementation

procedure AnimateControl(Control: TControl; AnimationType: TAnimationType;
  AnimationProperty: TAnimationProperty; Time: Integer; Movement: Integer;
  Delay: Integer = 0);
var
  I, J, iControlPos: Integer;

begin

  iControlPos := 0;
  I := 1;

  // Checking if the control already has existing animations
  while (I in [1 .. MaxAnimationControls]) and (iControlPos = 0) do
  begin
    if arrAnimationControls[I] <> nil then
      if (arrAnimationControls[I].FControl = Control) then
        iControlPos := I;

    Inc(I);
  end;

  I := 1;
  // If the control is not found it will be added at an empty array index
  if iControlPos = 0 then
    while (I in [1 .. MaxAnimationControls]) and (iControlPos = 0) do
    begin
      if arrAnimationControls[I] = nil then
      begin
        iControlPos := I;
        arrAnimationControls[I] := TAnimationControl.Create(Control);
      end;

      Inc(I);
    end;

  for J := 1 to MaxAnimations do
  begin

    if arrAnimationControls[iControlPos].FAnimations[J] = nil then
    begin
      arrAnimationControls[iControlPos].FAnimations[J] :=
        TAnimation.Create(AnimationType, AnimationProperty, Time,
        Movement, Delay);
      Exit;
    end;

  end;

end;

procedure AnimationTimer;
var
  I, iX, iTime, iMovement, iAnimationCount, iLastX: Integer;
  objAnimation: TAnimation;
  objAnimationControl: TAnimationControl;
  rOutput: Real;
  J: Integer;
  tStartTime: TTime;

begin

  tStartTime := now;

  for I := 1 to MaxAnimationControls do
  begin
    Application.ProcessMessages;

    objAnimationControl := arrAnimationControls[I];

    if objAnimationControl <> nil then
    begin

      iAnimationCount := 0;

      objAnimationControl.FLeftBool := False;
      objAnimationControl.FTopBool := False;
      objAnimationControl.FWidthBool := False;
      objAnimationControl.FHeightBool := False;

      for J := 1 to MaxAnimations do
      begin

        objAnimation := objAnimationControl.FAnimations[J];

        if objAnimation <> nil then
        begin

          Inc(iAnimationCount);

          with objAnimation do
          begin

            if FStartTime > now then
              iX := 0
            else
              iX := MilliSecondsBetween(now, FStartTime);

            iTime := FTime;
            iMovement := FMovement;

            if iX > iTime then
              iX := iTime;

            case FAnimationType of
              atLinear:
                rOutput := Linear(iMovement, iX, iTime);

              // Ease In
              atEaseInSine:
                rOutput := EaseInSine(iMovement, iX, iTime);
              atEaseInQuad:
                rOutput := EaseInQuad(iMovement, iX, iTime);
              atEaseInCubic:
                rOutput := EaseInCubic(iMovement, iX, iTime);
              atEaseInQuart:
                rOutput := EaseInQuart(iMovement, iX, iTime);
              atEaseInQuint:
                rOutput := EaseInQuint(iMovement, iX, iTime);
              atEaseInExpo:
                rOutput := EaseInQuint(iMovement, iX, iTime);
              atEaseInCirc:
                rOutput := EaseInCirc(iMovement, iX, iTime);
              atEaseInBack:
                rOutput := EaseInBack(iMovement, iX, iTime);
              atEaseInElastic:
                rOutput := EaseInElastic(iMovement, iX, iTime);

              // Ease Out
              atEaseOutSine:
                rOutput := EaseOutSine(iMovement, iX, iTime);
              atEaseOutQuad:
                rOutput := EaseOutQuad(iMovement, iX, iTime);
              atEaseOutCubic:
                rOutput := EaseOutCubic(iMovement, iX, iTime);
              atEaseOutQuart:
                rOutput := EaseOutQuart(iMovement, iX, iTime);
              atEaseOutQuint:
                rOutput := EaseOutQuint(iMovement, iX, iTime);
              atEaseOutExpo:
                rOutput := EaseOutQuint(iMovement, iX, iTime);
              atEaseOutCirc:
                rOutput := EaseOutCirc(iMovement, iX, iTime);
              atEaseOutBack:
                rOutput := EaseOutBack(iMovement, iX, iTime);
              atEaseOutElastic:
                rOutput := EaseOutElastic(iMovement, iX, iTime);

              // Ease In Out
              atEaseInOutSine:
                rOutput := EaseInOutSine(iMovement, iX, iTime);
              atEaseInOutQuad:
                rOutput := EaseInOutQuad(iMovement, iX, iTime);
              atEaseInOutCubic:
                rOutput := EaseInOutCubic(iMovement, iX, iTime);
              atEaseInOutQuart:
                rOutput := EaseInOutQuart(iMovement, iX, iTime);
              atEaseInOutQuint:
                rOutput := EaseInOutQuint(iMovement, iX, iTime);
              atEaseInOutExpo:
                rOutput := EaseInOutQuint(iMovement, iX, iTime);
              atEaseInOutCirc:
                rOutput := EaseInOutCirc(iMovement, iX, iTime);
              atEaseInOutBack:
                rOutput := EaseInOutBack(iMovement, iX, iTime);
              atEaseInOutElastic:
                rOutput := EaseInOutElastic(iMovement, iX, iTime);
            end;

            rOutput := rOutput - FPreviousCalc;
            FPreviousCalc := FPreviousCalc + rOutput;

          end; // with Animation

          with objAnimationControl do
          begin
            if objAnimation.FAnimationProperty = apLeft then
              FLeft := objAnimationControl.FLeft + rOutput
            else if objAnimation.FAnimationProperty = apTop then
              FTop := objAnimationControl.FTop + rOutput
            else if objAnimation.FAnimationProperty = apWidth then
              FWidth := objAnimationControl.FWidth + rOutput
            else if objAnimation.FAnimationProperty = apHeight then
              FHeight := objAnimationControl.FHeight + rOutput;

            FLeftBool := (objAnimation.FAnimationProperty = apLeft) or
              FLeftBool;
            FTopBool := (objAnimation.FAnimationProperty = apTop) or FTopBool;
            FWidthBool := (objAnimation.FAnimationProperty = apWidth) or
              FWidthBool;
            FHeightBool := (objAnimation.FAnimationProperty = apHeight) or
              FHeightBool;
          end; // with AnimationControl

          if iX = iTime then
          begin
            objAnimation := nil;
            arrAnimationControls[I].FAnimations[J] := nil;
            arrAnimationControls[I].FAnimations[J].Free;
          end;

        end; // if Animation <> nil
      end; // for J

      if iAnimationCount > 0 then
      begin

        with objAnimationControl do
        begin
          if FLeftBool then
            FControl.Left := ToInt(FLeft);

          { The if statement below counters the scroll movement from scroll
            boxes. For some reason, whenn you start scrolling in a scroll box
            the top position resets and stuff gets misaligned, especially if
            you happen to be animating and scrolling simultanesouly. This finds
            the difference between the last scroll position and the current
            scroll position, and adds it to the new top value to correct this }
          { } if FControl.Parent is TScrollBox then
          begin
            FTop := FTop + (FStartScrollPos - (FControl.Parent as TScrollBox)
              .VertScrollBar.ScrollPos);

            FStartScrollPos := (FControl.Parent as TScrollBox)
              .VertScrollBar.ScrollPos;

            Application.ProcessMessages;
          end; { }

          if FTopBool then
            FControl.Top := ToInt(FTop);

          if FWidthBool then
            FControl.Width := ToInt(FWidth);

          if FHeightBool then
            FControl.Height := ToInt(FHeight);
        end;

      end
      else
      begin
        arrAnimationControls[I] := nil;
        arrAnimationControls[I].Free;
      end;

    end; // if arrAnimationControls[I] <> nil
  end; // for I

end;

{ TAnimationObject }

constructor TAnimation.Create(AAnimationType: TAnimationType;
  AAnimationProperty: TAnimationProperty; ATime: Integer; AMovement: Integer;
  ADelay: Integer);
begin

  FAnimationType := AAnimationType;
  FAnimationProperty := AAnimationProperty;
  FTime := ATime;
  FMovement := AMovement;
  FStartTime := IncMilliSecond(now, ADelay);
  FPreviousCalc := 0;

end;

{ TAnimationControl }

constructor TAnimationControl.Create(AControl: TControl);
begin

  FControl := AControl;

  FLeft := FControl.Left;
  FTop := FControl.Top;
  FWidth := FControl.Width;
  FHeight := FControl.Height;

  if AControl.Parent is TScrollBox then
    FStartScrollPos := (AControl.Parent as TScrollBox).VertScrollBar.ScrollPos;

end;

function EaseInBack(iMovement, iX, iTime: Integer): Real;
begin
  Result := iMovement * (2.70158 * Power(iX / iTime, 3) - 1.70158 *
    Sqr(iX / iTime));
end;

function EaseInCirc(iMovement, iX, iTime: Integer): Real;
begin
  Result := iMovement * (1 - Sqrt(1 - Sqr(iX / iTime)));
end;

function EaseInCubic(iMovement, iX, iTime: Integer): Real;
begin
  Result := iMovement * Power(iX / iTime, 3);
end;

function EaseInElastic(iMovement, iX, iTime: Integer): Real;
begin
  if iX = 0 then
    Result := 0
  else if iX / iTime = 1 then
    Result := iMovement
  else
    Result := -iMovement * (Power(2, 10 * iX / iTime - 10) *
      Sin((iX / iTime * 10 - 10.75) * (2 * pi / 3)))
end;

function EaseInExpo(iMovement, iX, iTime: Integer): Real;
begin
  Result := iMovement * Power(2, 10 * iX / iTime - 10);
end;

function EaseInOutBack(iMovement, iX, iTime: Integer): Real;
begin
  if iX / iTime < 0.5 then
    Result := iMovement * (Sqr(2 * iX / iTime) * (3.5949095 * 2 * iX / iTime -
      2.5949095)) / 2
  else
    Result := iMovement * (Sqr(2 * iX / iTime - 2) *
      (3.5949095 * (iX / iTime * 2 - 2) + 2.5949095) + 2) / 2
end;

function EaseInOutCirc(iMovement, iX, iTime: Integer): Real;
begin
  if iX / iTime < 0.5 then
    Result := iMovement * (1 - Sqrt(1 - Sqr(2 * iX / iTime))) / 2
  else
    Result := iMovement * (Sqrt(1 - Sqr(-2 * iX / iTime + 2)) + 1) / 2
end;

function EaseInOutCubic(iMovement, iX, iTime: Integer): Real;
begin
  if iX / iTime < 0.5 then
    Result := iMovement * 4 * Power(iX / iTime, 3)
  else
    Result := iMovement * (1 - Power(-2 * iX / iTime + 2, 3) / 2);
end;

function EaseInOutElastic(iMovement, iX, iTime: Integer): Real;
begin
  if iX = 0 then
    Result := 0
  else if iX / iTime = 1 then
    Result := iMovement
  else if iX / iTime < 0.5 then
    Result := -iMovement * (Power(2, 20 * iX / iTime - 10) *
      Sin((20 * iX / iTime - 11.125) * (2 * pi / 4.5))) / 2
  else
    Result := iMovement * (Power(2, -20 * iX / iTime + 10) *
      Sin((20 * iX / iTime - 11.125) * (2 * pi / 4.5)) / 2 + 1)
end;

function EaseInOutExpo(iMovement, iX, iTime: Integer): Real;
begin
  if iX = 0 then
    Result := 0
  else if iX / iTime = 1 then
    Result := iMovement
  else if iX / iTime < 0.5 then
    Result := iMovement * Power(2, 20 * iX / iTime - 10) / 2
  else
    Result := iMovement * (2 - Power(2, -20 * iX / iTime + 10)) / 2;
end;

function EaseInOutQuad(iMovement, iX, iTime: Integer): Real;
begin
  if iX / iTime < 0.5 then
    Result := iMovement * 2 * Sqr(iX / iTime)
  else
    Result := iMovement * (1 - Sqr(-2 * iX / iTime + 2) / 2);
end;

function EaseInOutQuart(iMovement, iX, iTime: Integer): Real;
begin
  if iX / iTime < 0.5 then
    Result := iMovement * 8 * Power(iX / iTime, 4)
  else
    Result := iMovement * (1 - Power(-2 * iX / iTime + 2, 4) / 2);
end;

function EaseInOutQuint(iMovement, iX, iTime: Integer): Real;
begin
  if iX / iTime < 0.5 then
    Result := iMovement * 16 * Power(iX / iTime, 5)
  else
    Result := iMovement * (1 - Power(-2 * iX / iTime + 2, 5) / 2);
end;

function EaseInOutSine(iMovement, iX, iTime: Integer): Real;
begin
  Result := -iMovement * (cos(pi * iX / iTime) - 1) / 2;
end;

function EaseInQuad(iMovement, iX, iTime: Integer): Real;
begin
  Result := iMovement * Sqr(iX / iTime);
end;

function EaseInQuart(iMovement, iX, iTime: Integer): Real;
begin
  Result := iMovement * Power(iX / iTime, 4);
end;

function EaseInQuint(iMovement, iX, iTime: Integer): Real;
begin
  Result := iMovement * Power(iX / iTime, 5);
end;

function EaseInSine(iMovement, iX, iTime: Integer): Real;
begin
  Result := iMovement * (1 - cos((iX / iTime) * pi) / 2) - (iMovement / 2);
end;

function EaseOutBack(iMovement, iX, iTime: Integer): Real;
begin
  Result := iMovement * (1 + 2.70158 * Power(iX / iTime - 1, 3) + 1.70158 *
    Sqr(iX / iTime - 1))
end;

function EaseOutCirc(iMovement, iX, iTime: Integer): Real;
begin
  Result := iMovement * (Sqrt(1 - Sqr(iX / iTime - 1)));
end;

function EaseOutCubic(iMovement, iX, iTime: Integer): Real;
begin
  Result := iMovement * (1 - Power(1 - (iX / iTime), 3));
end;

function EaseOutElastic(iMovement, iX, iTime: Integer): Real;
begin
  if iX = 0 then
    Result := 0
  else if iX / iTime = 1 then
    Result := iMovement
  else
    Result := iMovement * (Power(2, -10 * iX / iTime) *
      Sin((iX / iTime * 10 - 0.75) * (2 * pi / 3)) + 1)

end;

function EaseOutExpo(iMovement, iX, iTime: Integer): Real;
begin
  Result := iMovement * (1 - Power(2, -10 * iX / iTime));
end;

function EaseOutQuad(iMovement, iX, iTime: Integer): Real;
begin
  Result := iMovement * (1 - Sqr(1 - iX / iTime));
end;

function EaseOutQuart(iMovement, iX, iTime: Integer): Real;
begin
  Result := (iMovement * (1 - Power(1 - (iX / iTime), 4)));
end;

function EaseOutQuint(iMovement, iX, iTime: Integer): Real;
begin
  Result := iMovement * (1 - Power(1 - (iX / iTime), 5));
end;

function EaseOutSine(iMovement, iX, iTime: Integer): Real;
begin
  Result := iMovement * Sin(iX / iTime * pi / 2);
end;

function Linear(iMovement, iX, iTime: Integer): Real;
begin
  Result := iMovement * (iX / iTime);
end;

end.
