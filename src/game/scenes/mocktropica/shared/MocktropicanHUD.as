package game.scenes.mocktropica.shared {

import flash.display.DisplayObjectContainer;
import flash.display.MovieClip;
import flash.geom.Point;

import ash.core.Entity;

import engine.components.Audio;
import engine.components.Display;
import engine.components.Id;
import engine.components.Motion;
import engine.components.Spatial;
import engine.managers.SoundManager;

import game.components.entity.Sleep;
import game.components.motion.Threshold;
import game.components.timeline.Timeline;
import game.data.sound.SoundModifier;
import game.systems.SystemPriorities;
import game.systems.motion.ThresholdSystem;
import game.ui.hud.Hud;
import game.ui.hud.HudPopBrowser;
import game.util.EntityUtils;
import game.util.TimelineUtils;

import org.osflash.signals.Signal;

/**
 * MocktropicanHUD implements a temporary replacement HUD.
 * @author Rich Martin
 */
public class MocktropicanHUD extends HudPopBrowser {

	public static const INVISIBLE:Boolean	= false;
	public static const VISIBLE:Boolean		= true;
	private static const GLITCH:String = 	"static_01.mp3";
	private static const SHATTER:String =	"crab_explode_01.mp3";
	public var glitchEnt:Entity;

	private static const GLITCHED_INVENTORY_ASSET:String = '/scenes/mocktropica/shared/glitchedInventory.swf';

	public var shouldDemonstrateCriticalBug:Boolean;
	public var demonstrationCompleted:Signal;

	public function MocktropicanHUD(container:DisplayObjectContainer=null)
	{
		super(container);

		demonstrationCompleted = new Signal();
	}
	
	public override function destroy():void
	{
		demonstrationCompleted.removeAll();
		super.destroy();
	}

	public override function loaded():void 
	{
		super.loaded();

		var inventoryHasBroken:Boolean = shellApi.checkEvent('inventory_broken');
		var inventoryHasBeenFixed:Boolean = shellApi.checkEvent('inventory_fixed');
		if (inventoryHasBroken && !inventoryHasBeenFixed) {
			showInventoryButton(INVISIBLE);
		}
	}

	public override function openHud(opening:Boolean=true):void
	{
		super.openHud(opening);
		if (opening) {
			_hudSystem.onComplete.addOnce(chestListener);
		}
	}

	private function showInventoryButton(shouldShow:Boolean):void {
		if (!_inventoryBtn) {
			trace("Inventory button is null, therefore it can't be shown at all.");
			return;
		}

		hideButton(Hud.INVENTORY, !shouldShow);
	}

	private function chestListener():void
	{
		if (isOpen) {
			if (shouldDemonstrateCriticalBug) {
				shellApi.loadFile( shellApi.assetPrefix + GLITCHED_INVENTORY_ASSET, runCriticalBugDemonstration);
				shouldDemonstrateCriticalBug = false;
			}
		}
	}
	
	private function runCriticalBugDemonstration( asset:MovieClip ):void
	{
	//	enableHUDButtons(false, true);
		glitchEnt = EntityUtils.createMovingEntity( this, asset.contents, container );
		glitchEnt.add( new Id( "glitch" ));
		glitchEnt.add( new Audio());
		glitchEnt.name = 'glitch';
		var spatial:Spatial = _inventoryBtn.get(Spatial) as Spatial;
		EntityUtils.position( glitchEnt, spatial.x, spatial.y );

		TimelineUtils.convertClip( asset.contents, this, glitchEnt );
		var timeline:Timeline = glitchEnt.get( Timeline );
		timeline.labelReached.add( inventoryLabelHandler )

		var threshold:Threshold = new Threshold( "y", ">=" );
		threshold.threshold = shellApi.viewportHeight - ( asset.contents.height * .5 );
		threshold.entered.addOnce( explodeInventory );
		glitchEnt.add( threshold );
		addSystem( new ThresholdSystem(), SystemPriorities.update );
		hideButton( Hud.INVENTORY, true );
//		Sleep( _inventoryBtn.get( Sleep )).sleeping = true;
//		removeEntity( _inventoryBtn );
		
		var sleep:Sleep = glitchEnt.get( Sleep );
		sleep.ignoreOffscreenSleep = true;
	}
	
	private function inventoryLabelHandler(eventName:String):void
	{
		var audio:Audio = glitchEnt.get( Audio );
		
		switch (eventName) {
			case "glitchIntro":
				audio.play( SoundManager.EFFECTS_PATH + GLITCH, false, SoundModifier.POSITION );
				break;
			case "startFall":
				var motion:Motion = getEntityById('glitch').get(Motion) as Motion;
				if (0 == motion.velocity.y) {
					motion.velocity.y = 500;
					motion.acceleration = new Point( 0, 250 );
					motion.maxVelocity = new Point( 0, 2000 );
				}
				break;
			case "endShatter":
				closeBrokenHud();
				break;
			case "shatter":
				audio.play( SoundManager.EFFECTS_PATH + SHATTER, false, SoundModifier.POSITION );
				break;
			default:
				break;
		}
	}

	private function explodeInventory():void
	{
		var spatial:Spatial = glitchEnt.get( Spatial );
		var display:Display = glitchEnt.get( Display );
		
		spatial.y = shellApi.viewportHeight - ( display.displayObject.height * .5 );
		
		var timeline:Timeline = glitchEnt.get( Timeline );
		var motion:Motion = glitchEnt.get( Motion );
		
		motion.velocity = new Point( 0, 0 );
		motion.acceleration = new Point( 0, 0 );
		motion.previousAcceleration = new Point( 0, 0 );
		motion.totalVelocity.y = 0
		
		timeline.gotoAndPlay( "shatter" );
	}

	private function closeBrokenHud():void
	{
		shellApi.triggerEvent( "inventory_broken", true );
		openHud(false);

		demonstrationCompleted.dispatch();
	}

}

}
