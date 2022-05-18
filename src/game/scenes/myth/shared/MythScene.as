package game.scenes.myth.shared
{	
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.Sprite;
	
	import ash.core.Entity;
	
	import engine.components.Audio;
	import engine.components.Display;
	import engine.components.Id;
	import engine.components.Spatial;
	import engine.components.Tween;
	import engine.util.Command;
	
	import game.components.render.Light;
	import game.components.render.LightOverlay;
	import game.components.specialAbility.SpecialAbilityControl;
	import game.data.TimedEvent;
	import game.data.character.LookAspectData;
	import game.data.character.LookData;
	import game.data.game.GameEvent;
	import game.data.specialAbility.SpecialAbilityData;
	import game.scene.template.AudioGroup;
	import game.scene.template.PlatformerGameScene;
	import game.scenes.myth.MythEvents;
	import game.scenes.myth.shared.abilities.Electrify;
	import game.scenes.myth.shared.abilities.Grow;
	import game.systems.render.LightSystem;
	import game.util.EntityUtils;
	import game.util.SceneUtil;
	import game.util.SkinUtils;
	
	public class MythScene extends PlatformerGameScene
	{
		public function MythScene()
		{
			super();
		}
		
		override public function loaded():void
		{
			_events = super.events as MythEvents;
			_audioGroup = getGroupById( AudioGroup.GROUP_ID ) as AudioGroup;
			
			removeIslandParts();
			super.loaded();
		}
		
		public function removeIslandParts():void
		{
			var specialAbilityControl:SpecialAbilityControl = super.player.get( SpecialAbilityControl );
			var specialAbilityData:SpecialAbilityData;
			var lookAspectData:LookAspectData;
			var lookData:LookData;
			
			if( specialAbilityControl ) 
			{
				var requireSave:Boolean = false;
				
				for each( specialAbilityData in specialAbilityControl.specials )
				{
					if( specialAbilityData.id == "Grow" && !shellApi.checkEvent( GameEvent.GOT_ITEM + _events.HADES_CROWN ))
					{
						lookAspectData = SkinUtils.getLookAspect( player, SkinUtils.HAIR );
						lookData = new LookData();
						lookData.applyAspect( lookAspectData );
						
						specialAbilityControl.removeSpecialByClass( Grow );
						SkinUtils.setSkinPart( player, SkinUtils.HAIR, "hades2" );
						requireSave = true;
					}
					else if( specialAbilityData.id == "Electrify" && !shellApi.checkEvent( GameEvent.GOT_ITEM + _events.POSEIDON_TRIDENT ))
					{
						lookAspectData = SkinUtils.getLookAspect( player, SkinUtils.ITEM );
						lookData = new LookData();
						lookData.applyAspect( lookAspectData );
						
						specialAbilityControl.removeSpecialByClass( Electrify );
						SkinUtils.removeLook( player, lookData );
						requireSave = true;
					}
				}
				
				if( requireSave ) { super.shellApi.saveLook(); }
			}	
		}
		
		// ZEUS LIGHTNING
		protected function createLightningCover():void
		{
			var bitmapData:BitmapData = new BitmapData( shellApi.viewportWidth, shellApi.viewportHeight, false, 0xffffffff );
			var bitmap:Bitmap = new Bitmap( bitmapData );
			
			var sprite:Sprite = new Sprite();
			sprite.addChild( bitmap );
			
			var entity:Entity = EntityUtils.createSpatialEntity( this, sprite, super.overlayContainer );
			var tween:Tween = new Tween();
			entity.add( tween ).add( new Id( "zeusFlash" ));
			
			_audioGroup.addAudioToEntity( entity );
			var audio:Audio = entity.get( Audio );
			audio.playCurrentAction( "enter" );
			
			var display:Display = entity.get( Display );
			display.alpha = 0;
			
			_flashing = true;
			
			startFlash( entity );
		}
		
		private function temperFlash( entity:Entity, handler:Function ):void
		{
			if( _flashing )
			{
				SceneUtil.addTimedEvent( this, new TimedEvent(( Math.random() * 2 ) + 2, 1, Command.create( handler, entity ))); 
			}
			else
			{
				removeEntity( entity );
			}
		}
		
		protected function addLight(entity:Entity, radius:Number = 400, darkAlpha:Number = .9, gradient:Boolean = true):void
		{
			var lightOverlayEntity:Entity = super.getEntityById("lightOverlay");
			
			if(lightOverlayEntity == null)
			{
				super.addSystem(new LightSystem());
				
				var lightOverlay:Sprite = new Sprite();
				super.overlayContainer.addChildAt(lightOverlay, 0);
				//super.overlayContainer.mouseEnabled = false;
				lightOverlay.mouseEnabled = false;
				lightOverlay.mouseChildren = false;
				lightOverlay.graphics.clear();
				lightOverlay.graphics.beginFill(0x000000, darkAlpha);
				lightOverlay.graphics.drawRect(0, 0, super.shellApi.viewportWidth, super.shellApi.viewportHeight);
				
				var display:Display = new Display(lightOverlay);
				display.isStatic = true;
				
				lightOverlayEntity = new Entity();
				lightOverlayEntity.add(new Spatial());
				lightOverlayEntity.add(display);
				lightOverlayEntity.add(new Id("lightOverlay"));
				lightOverlayEntity.add(new LightOverlay(darkAlpha));
				
				super.addEntity(lightOverlayEntity);
			}
			
			entity.add(new Light(radius, darkAlpha, 0, gradient));
		}
		
		private function startFlash( entity:Entity ):void
		{
			var audio:Audio = entity.get( Audio );
			var display:Display = entity.get( Display );
			var path:String = "random";
			var tween:Tween = entity.get( Tween );
			
			switch( Math.floor( Math.random() * 2 ))
			{
				case 0:
					break;
				case 1:
					path += "1";
					break;
				case 2: 
					path += "2";
					break;
			}
			
			trace( path );
			
			audio.playCurrentAction( path )
			tween.to( display, Math.random() * .4, { alpha : 1, onComplete : fadeFlash, onCompleteParams : [ entity ]});
		}
		
		private function fadeFlash( entity:Entity ):void
		{
			var tween:Tween = entity.get( Tween );
			var display:Display = entity.get( Display );
			
			tween.to( display, Math.random() * .4, { alpha : 0, onComplete : temperFlash, onCompleteParams : [ entity, startFlash ]});
		}
		
		protected var _flashing:Boolean = false;
		protected var _audioGroup:AudioGroup;
		protected var _events:MythEvents;
	}
}