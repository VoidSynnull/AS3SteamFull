package game.ui.elements {

import engine.group.UIView;



/**
 * BlimpConfirmationView
 * @author Rich Martin
 */
public class BlimpConfirmationView extends UIView {

	import flash.display.*;
	import flash.events.Event;
	import flash.geom.Point;
	import flash.text.*;
	import game.creators.ui.ButtonCreator;
	import game.data.ui.ButtonSpec;
	import game.scene.template.SceneUIGroup;
	import game.ui.elements.MultiStateButton;
	import org.osflash.signals.Signal;

	public static const GROUP_PREFIX:String = 'ui/hud/';
	public static const PANEL_ASSET:String = 'blimpConfirmation.swf';

	public static const LEFT_MESSAGE:String = 'are you sure you want to return to poptropica?';
	public static const RIGHT_MESSAGE:String = 'tell us what you think!\nyour feedback will help us make the game better.';

	public static const RETURN_TO_MAP:uint	= 0;
	public static const SEND_FEEDBACK:uint	= 1;
	public static const CANCEL:uint			= 2;

	public var message:String;
	public var buttonClicked:Signal;

	private var okButton:MultiStateButton;
	private var surveyButton:MultiStateButton;
	private var redX:MultiStateButton;

	public function BlimpConfirmationView() {
		buttonClicked = new Signal(uint);
		super();
	}
	
	//// ACCESSORS ////
	
	//// PUBLIC METHODS ////

	public override function init(superView:DisplayObjectContainer=null):void {
		groupPrefix = GROUP_PREFIX;
		super.init(superView);
		load();
	}

	public override function load():void {
		shellApi.fileLoadComplete.addOnce(loaded);
		loadFiles([PANEL_ASSET]);
	}

	public override function loaded():void {
		const REMOVE_FROM_CACHE:Boolean = true;
		var swf:MovieClip = getAsset(PANEL_ASSET, REMOVE_FROM_CACHE) as MovieClip;
		screen = swf.content;
		groupContainer.addChild(screen);
	/*	TextRenderer.displayMode = TextDisplayMode.LCD;
		screen.messageL.antiAliasType = screen.messageLshadow.antiAliasType = AntiAliasType.ADVANCED;
		screen.messageR.antiAliasType = screen.messageRshadow.antiAliasType = AntiAliasType.ADVANCED;
		screen.messageL.embedFonts = screen.messageLshadow.embedFonts = true;
		screen.messageR.embedFonts = screen.messageRshadow.embedFonts = true;
		var messageFormat:TextFormat = new TextFormat('Billy Serif', 24, 0xffffff, null, null, null, null, null, TextFormatAlign.CENTER, null, null, null, 1.2);
		messageFormat.letterSpacing = -.33;
		var shadowFormat:TextFormat = new TextFormat('CreativeBlock BB', 24, 0x000000, null, null, null, null, null, TextFormatAlign.CENTER, null, null, null, 1.2);
		shadowFormat.letterSpacing = -.33;
		screen.messageL.defaultTextFormat = messageFormat;
		screen.messageLshadow.defaultTextFormat = shadowFormat;
		screen.messageR.defaultTextFormat = messageFormat;
		screen.messageRshadow.defaultTextFormat = shadowFormat;*/
		screen.messageL.wordWrap = screen.messageLshadow.wordWrap = true;
		screen.messageL.autoSize = screen.messageLshadow.autoSize = TextFieldAutoSize.CENTER;
		screen.messageR.wordWrap = screen.messageRshadow.wordWrap = true;
		screen.messageR.autoSize = screen.messageRshadow.autoSize = TextFieldAutoSize.CENTER;
		screen.messageLshadow.alpha = screen.messageRshadow.alpha = .20;
		screen.messageL.text = screen.messageLshadow.text = LEFT_MESSAGE;
		screen.messageR.text = screen.messageRshadow.text = RIGHT_MESSAGE;

		var uiGroup:SceneUIGroup = getGroupById('ui') as SceneUIGroup;
		var btnSpec:ButtonSpec = ButtonSpec.instanceFromInitializer({displayObjectContainer:screen.okBtn, pressAction:playClick, clickHandler:onButtonClick});
		okButton = MultiStateButton.instanceFromButtonSpec(btnSpec);
		btnSpec.displayObjectContainer = screen.surveyBtn;
		surveyButton = MultiStateButton.instanceFromButtonSpec(btnSpec);

		var closeBtnSpec:ButtonSpec = new ButtonSpec();
		closeBtnSpec.parentGroup = this;
		closeBtnSpec.container = screen;
		closeBtnSpec.position = new Point(screen.width-18,18);
		closeBtnSpec.clickHandler = onButtonClick;
		closeBtnSpec.pressAction = playCancel;
		redX = ButtonCreator.loadMultiStateButton(ButtonCreator.CLOSE_BUTTON, closeBtnSpec);

		super.loaded();
	}

	public override function destroy():void {
		if (buttonClicked) buttonClicked.removeAll();
		super.destroy();
	}
	
	//// INTERNAL METHODS ////

	//// PROTECTED METHODS ////

	//// PRIVATE METHODS ////
	
	private function onButtonClick(e:Event):void {
		switch(e.target.name) {
			case 'okBtn':
				buttonClicked.dispatch(RETURN_TO_MAP);
				break;
			case 'surveyBtn':
				buttonClicked.dispatch(SEND_FEEDBACK);
				break;
			case 'content':
				buttonClicked.dispatch(CANCEL);
				break;
			default:
				break;
		}
	}

}

}
