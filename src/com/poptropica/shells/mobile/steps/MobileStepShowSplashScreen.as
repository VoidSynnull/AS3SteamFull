package com.poptropica.shells.mobile.steps {
import flash.display.Bitmap;
import flash.display.Sprite;
import flash.text.AntiAliasType;
import flash.text.TextField;
import flash.text.TextFieldAutoSize;
import flash.text.TextFormat;

import game.util.DataUtils;
import game.util.DisplayPositionUtils;

public class MobileStepShowSplashScreen extends ShellStep {

	public static const MESSAGE_FONT:String			= 'CreativeBlock BB';
	public static const MESSAGE_FONT_SIZE:Number	= 26;
	public static const MESSAGE_FONT_COLOR:uint		= 0xBAC6E0;
	public static const BOTTOM_MARGIN:Number		= 10;

	[Embed(source="/Default-Landscape.png")]
	private var SplashClass:Class;
	private var _splashContainer:Sprite;
	private var _splashTextField:TextField;

	//// CONSTRUCTOR ////

	public function MobileStepShowSplashScreen()
	{
		super();
	}

	//// ACCESSORS ////

	internal function get message():String
	{
		return _splashTextField ? _splashTextField.text : '';
	}

	//// PUBLIC METHODS ////

	//// INTERNAL METHODS ////

	//// PROTECTED METHODS ////

	protected override function build():void
	{
		shell.stepChanged.add(updateSplashScreenText);
		shell.complete.addOnce(removeSplashScreen);
		showSplashScreen();
		built();
	}

	//// PRIVATE METHODS ////

	private function showSplashScreen():void
	{
		var splashImage:Bitmap = new SplashClass() as Bitmap;

		DisplayPositionUtils.fillDimensions(splashImage, shellApi.viewportWidth, shellApi.viewportHeight);

		_splashContainer = new Sprite();
		_splashContainer.addChild(splashImage);
		shellApi.screenManager.overlayContainer.addChild(_splashContainer);
	}

	private function updateSplashScreenText(step:ShellStep):void
	{
		if ( _splashTextField == null ) {
			_splashContainer.addChild(createSplashTextField());
		}

		var stepText:String = step.stepDescription;
		if (stepText) {
			_splashTextField.text = stepText;
		}
	}

	private function removeSplashScreen(shell:Shell):void
	{
		shellApi.screenManager.overlayContainer.removeChild(_splashContainer);
		_splashContainer = null;
		_splashTextField = null;
	}

	private function createSplashTextField():TextField
	{
		_splashTextField = new TextField();
		_splashTextField.defaultTextFormat	= new TextFormat(MESSAGE_FONT, MESSAGE_FONT_SIZE, MESSAGE_FONT_COLOR);
		_splashTextField.text				= "ABCDEFGHIJKLMNOPQRSTUVWXYZ abcdefghijklmnopqrstuvwxyz";
		_splashTextField.embedFonts			= true;
		_splashTextField.antiAliasType		= AntiAliasType.NORMAL;
		_splashTextField.autoSize			= TextFieldAutoSize.CENTER;
		_splashTextField.x					= shellApi.viewportWidth / 2 - (_splashTextField.textWidth / 2);
		_splashTextField.y					= shellApi.viewportHeight - (_splashTextField.textHeight + BOTTOM_MARGIN);
		_splashTextField.text				= '';

		return _splashTextField;
	}

	//// INTERFACE IMPLEMENTATIONS ////
}

}
