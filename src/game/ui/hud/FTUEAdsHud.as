package game.ui.hud {

import flash.display.DisplayObjectContainer;

public class FTUEAdsHud extends HudPopBrowser {

	//// CONSTRUCTOR ////

	public function FTUEAdsHud(container:DisplayObjectContainer=null)
	{
		super(container);
	}

	//// ACCESSORS ////

	//// PUBLIC METHODS ////

	//// INTERNAL METHODS ////

	//// PROTECTED METHODS ////

//	override protected function createHomeButton( btnClip:MovieClip, index:int, name:String, startSpatial:Spatial ):void 
//	{
//		trace("MAKING THE HOME BUTTON FOR ALL", btnClip, index, name, startSpatial);
//		super.createHomeButton( btnClip, index, name, startSpatial );
//	}

	protected override function goToHome():void
	{
		shellApi.loadScene((shellApi.sceneManager).gameData.homeClass);
	}

	//// PRIVATE METHODS ////

	//// INTERFACE IMPLEMENTATIONS ////

}

}
