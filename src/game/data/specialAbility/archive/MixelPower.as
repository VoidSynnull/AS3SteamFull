// Status: retired
// Usage (2) ads
// Used by cards 2508, 2509

package game.data.specialAbility.character
{	
	import flash.display.MovieClip;
	import flash.geom.Point;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Id;
	import engine.components.Spatial;
	import engine.group.Scene;
	
	import game.data.animation.Animation;
	import game.data.specialAbility.SpecialAbility;
	import game.nodes.specialAbility.SpecialAbilityNode;
	import game.scenes.backlot.sunriseStreet.Systems.EarthquakeSystem;
	import game.scenes.backlot.sunriseStreet.components.Earthquake;
	import game.util.EntityUtils;
	import game.util.SceneUtil;
	import game.util.TimelineUtils;
	
	/**
	 * Load popup animation with camera shake 
	 */
	public class MixelPower extends SpecialAbility
	{
		override public function activate( node:SpecialAbilityNode ):void
		{
			if ( !super.data.isActive )
			{
				// make active
				super.setActive( true );
				
				// get swf path and load
				var swfPath:String = String( super.data.params.byId( "swfPath" ) );			
				super.loadAsset(swfPath, loadComplete);
			}
		}
		
		private function loadComplete(clip:MovieClip):void
		{
			if (clip == null)
				return;
			// remember clip
			_clip = clip;
			
			// Add the MovieClip to scene	
			super.entity.get(Display).container.addChild(clip);
			
			var entity:Entity = EntityUtils.createSpatialEntity( super.group, clip, super.entity.get(Display).container );
			
			// Create the new entity and set the display and spatial
			var objectEntity:Entity = new Entity();
			objectEntity.add(new Display(clip, super.entity.get(Display).container));
			super.group.addEntity(objectEntity);
			
			var charSpatial:Spatial = super.entity.get(Spatial);
			var spatial:Spatial = entity.get( Spatial );
			
			spatial.x = charSpatial.x;
			spatial.y = charSpatial.y + 35;
			
			// this converts the content clip for AS3super.group
			var vTimeline:Entity = TimelineUtils.convertClip(clip.content, super.group);
			TimelineUtils.onLabel( vTimeline, Animation.LABEL_ENDING, endPopupAnim );
			
			TimelineUtils.onLabel(vTimeline, "hideChar", hideChar);
			TimelineUtils.onLabel(vTimeline, "startShake", startShake);
			
			// disable user input
			SceneUtil.lockInput(super.group, true);
		}
		
		private function hideChar():void
		{
			super.entity.get(Display).alpha = 0;
		}
		
		private function startShake():void
		{
			// Add the earthquake system if it's not there
			if( !super.group.getSystem( EarthquakeSystem ) )
			{
				super.group.addSystem( new EarthquakeSystem() );
			}
			
			var cameraShake:Entity = EntityUtils.createSpatialEntity(super.group,new MovieClip(), super.entity.get(Display).container);
			cameraShake.add(new Earthquake(super.entity.get(Spatial),new Point(1,10),30,80)).add(new Id("cameraShake"));
			SceneUtil.setCameraTarget(Scene(super.group), cameraShake);
		}
		
		private function endPopupAnim():void
		{
			// remove clip
			super.entity.get(Display).container.removeChild(_clip);
			
			//reveal char
			super.entity.get(Display).alpha = 1;
			
			//stop shake
			SceneUtil.setCameraTarget(Scene(super.group), super.entity);
			super.group.removeEntity(super.group.getEntityById("cameraShake"));
			
			// enable user input
			SceneUtil.lockInput(super.group, false);
			
			// make inactive
			super.setActive( false );
		}
		
		private var _clip:MovieClip;
	}
}