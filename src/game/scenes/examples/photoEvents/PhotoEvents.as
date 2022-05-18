package game.scenes.examples.photoEvents {

import flash.display.DisplayObjectContainer;

import game.data.game.GameEvent;
import game.scene.template.PhotoGroup;
import game.scene.template.PlatformerGameScene;
import game.ui.popup.Popup;

// If your scene class extends PlatformerGameScene (or ShipScene a la Virus Hunter),
// its assetsLoaded() method will instantiate a PhotoGroup, whose setupScene() method
// will parse a photos.xml data file (if one has been found) and set up the event triggers for
// each <photo> element which has not yet been taken.

// NOTA BENE: Restarting an island does not remove any photos from a player's account.
// Once taken, a photo will NEVER be re-taken (unless the player manually deletes the photo).
// This means taking a photo is an OPTIONAL item in the sequence of actions in a scene.
public class PhotoEvents extends PlatformerGameScene {

	// Normally, photo IDs are defined in photos.xml to correspond with their ID value in the CMS.
	// In this example scene, we are using arbitrary string IDs with no particular meaning.
	public static const PHOTO_ID_0:String	= 'test0';
	public static const PHOTO_ID_1:String	= 'test1';
	public static const PHOTO_ID_2:String	= 'test2';

	// The 'johnDoe' NPC will trigger this in-scene event when his conversation completes
	public static const DO_PHOTO:String		= "doPhoto";
	// We handle the 'doPhoto' scene event by triggering the 'npc_photo' photo event
	public static const NPC_PHOTO:String	= 'npc_photo';

	/*
		In the simplest case, merely adding an appropriate photos.xml
		file to scene.xml is all that needs to be done to equip a scene
		with photos. Both PHOTO_ID_0 and PHOTO_ID_1 are simple cases,
		and no code needs to be added to the scene class. As conditions are
		satisfied, photo events occur simultaneously with ordinary scene activities.

		Very often the conditions for awarding a photo do not fit quite so well,
		and it becomes necessary to write scene code to integrate the photo
		into the sequence of events. Perhaps the most common example is when
		a photo is triggered as a result of completing a scene. Normally, one
		writes 'shellApi.loadScene(someScene)' at this point, but some care
		must be taken to insure that the photo notification has time to run
		and be noticed. PHOTO_ID_2 is an example of such a case. See the method
		'demoPhotoEvent()' to view a typical implementation.
	*/
	public function PhotoEvents()
	{
		super();
	}
	
	// pre load setup
	override public function init(container:DisplayObjectContainer = null):void
	{			
		groupPrefix = "scenes/examples/photoEvents/";
		
		super.init(container);
	}
	
	// initiate asset load of scene specific assets.
	override public function load():void
	{
		shellApi.removeEvent(GameEvent.HAS_ITEM + 'crowbar');
		shellApi.removeEvent(GameEvent.GOT_ITEM + 'crowbar');
		shellApi.removePhoto(PHOTO_ID_0);
		shellApi.removePhoto(PHOTO_ID_1);
		shellApi.removePhoto(PHOTO_ID_2);

		super.load();
	}
	
	// all assets ready
	override public function loaded():void
	{
		shellApi.eventTriggered.add(handleEventTriggered);

		super.loaded();
	}

	private function handleEventTriggered(eventName:String, makeCurrent:Boolean=true, init:Boolean=false, removeEvent:String=null):void
	{
		switch (eventName) {
			case 'doPhoto':		// in this case, we handle an arbitrary scene event by manually triggering a photo event 
				demoPhotoEvent();
				break;
			default:
				trace("did not handle", eventName);
				break;
		}
	}

	private function demoPhotoEvent():void
	{
		/*
			Bear in mind that a photo event, despite having its conditions fully satisfied,
			may not occur at all if the player already possesses the photo in their Photo Album.
			One handles such a case by simply advancing the scene to its next stage without
			waiting for a notification sequence to complete.
		*/
		shellApi.takePhotoByEvent(NPC_PHOTO, doTheNextThing );
	}
	
	private function extraCheck():void
	{
		/*
			In some extrmee cases you may have to wait until a popup has finished before you can tale the picture.
			This is because the photo notification animation is part of the hud (want to change this though),
			so in order to see the photo notification you would need to return to the scene, 
			say instead of loading directly into the next scene from the popup.
		
			In this scenario you may need to check to see if the photo needs to be taken.
			This is a rather odd scenario though, and should best be avoided if possible.
		*/
		var photoGroup:PhotoGroup = getGroupById(PhotoGroup.GROUP_ID) as PhotoGroup;
		if (photoGroup && photoGroup.shouldTakePhoto("12650") ) 
		{
			var popup:Popup = getGroupById('somePopup') as Popup;
			popup.removed.addOnce(takePhoto);
			popup.close();
		} 
		else 
		{
			doTheNextThing();
		}
	}
	
	private function takePhoto():void
	{
		shellApi.takePhoto("12650", doTheNextThing );
	}
	
	private function doTheNextThing():void
	{
		trace("you might want to load a new scene or something, now that the photo notification is complete");
	}
}
}