package game.scenes.mocktropica.shared.popups
{
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	
	import ash.core.Entity;
	
	import engine.components.Audio;
	import engine.components.AudioRange;
	import engine.components.Id;
	import engine.components.Spatial;
	import engine.systems.CameraSystem;
	
	import game.components.motion.FollowTarget;
	import game.creators.ui.ToolTipCreator;
	import game.scenes.mocktropica.shared.components.AdvertisementComponent;
	import game.systems.motion.FollowTargetSystem;
	import game.systems.SystemPriorities;
	import game.ui.popup.Popup;
	import game.util.EntityUtils;
	
	public class MocktropicaAdvertisementPopup extends Popup
	{
		public function MocktropicaAdvertisementPopup( level:int = 0, container:DisplayObjectContainer = null )
		{
			super( container );
			_level = level;
		}
		
		override public function init( container:DisplayObjectContainer = null ):void
		{
			super.groupPrefix = "";//"scenes/mocktropica/shared/";
			this.screenAsset = "scenes/mocktropica/shared/customvertisements.swf";
			
			super.init( container );
			
			super.autoOpen = false;
			
			if( _level != 2 )
			{
				super.pauseParent = false;
			}
			
			load();
		}
		
		override public function destroy():void
		{
			super.destroy();
		}
		
		override public function load():void
		{
			super.load();
//			super.shellApi.fileLoadComplete.addOnce( loaded );
//			super.loadFiles( new Array( "advertisements.swf" ));
		}
		
		override public function loaded():void
		{
			super.screen = super.getAsset( this.screenAsset, false ) as MovieClip;
			super.addSystem( new FollowTargetSystem(), SystemPriorities.move );
			
			var boss:Boolean = false;
			
			if( _level > 0 )
			{
				boss = true;
			}
			
			createAd( boss );
			
			super.loaded();
			super.open();
		}
		
		private function createAd( boss:Boolean ):void
		{
			var clip:MovieClip;
			var entity:Entity;
			var hitEnt:Entity;
			var ad:AdvertisementComponent = new AdvertisementComponent();
			
			var randomX:Number = ( Math.random() * 40 ) - 20;
			var randomY:Number = ( Math.random() * 40 ) - 20;
			
			var camera:CameraSystem = super.shellApi.camera;
			var spatial:Spatial;
			var playerSpatial:Spatial = super.shellApi.player.get( Spatial );
			
			hitEnt = EntityUtils.createMovingEntity( this, super.screen.content.getChildByName( "hit" ));
			
			if( boss )
			{
				entity = EntityUtils.createSpatialEntity( this, super.screen.content.getChildByName( "level" + _level )); 
				hitEnt.add( new Id( "ad_hit" + _level ));	
				
				entity.add( new Id( "ad_boss" + _level ));
				
				ad.level = _level;
				ad.maxHits = _level * 3;
				
				if( ad.level == 3 )
				{
					EntityUtils.position( entity, playerSpatial.x + randomX, playerSpatial.y + randomY );
					EntityUtils.positionByEntity( hitEnt, entity );
					
					ad.camera = camera;
				}
				else
				{
					EntityUtils.position( entity, ( Math.random() * super.shellApi.viewportWidth ), ( Math.random() * super.shellApi.viewportHeight ));
					EntityUtils.positionByEntity( hitEnt, entity );
				}
			}
			else
			{
				var popupNumber:uint = Math.abs( Math.random() * 5 ) + 1;
				
				entity = EntityUtils.createSpatialEntity( this, super.screen.content.getChildByName( "popup" + popupNumber ));			
				hitEnt.add( new Id( "random_ad_hit" ));
				
				entity.add( new Id( "random_ad" ));
				
				ad.level = 0;
				ad.maxHits = 1;
				
				EntityUtils.position( entity, ( Math.random() * camera.viewport.width ) + camera.viewport.x, ( Math.random() * camera.viewport.height ) + camera.viewport.top );
				EntityUtils.positionByEntity( hitEnt, entity );
			}
			
			spatial = hitEnt.get( Spatial );
			ad.visual = entity;
			ad.target = new Spatial( spatial.x, spatial.y );
			ad.popup = this;			
			
			
			
			hitEnt.add( ad ).add( new Audio() ).add( new AudioRange( 600, 0, 1 ));
			ToolTipCreator.addToEntity( hitEnt );
			entity.add( new FollowTarget( spatial ));
			
			
			clip = super.screen.content.hit.getChildByName( "flame" );
			ad.flame = clip;
		}
		
		private static const TORCH:String =			"torch_fire_01_l.mp3";
		
		private var _level:int;
	}
}