package game.scenes.myth.mountOlympus2
{
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.filters.GlowFilter;
	import flash.geom.Matrix;
	import flash.geom.Rectangle;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Id;
	import engine.components.Interaction;
	import engine.components.Spatial;
	import engine.components.SpatialAddition;
	import engine.components.Tween;
	import engine.util.Command;
	
	import fl.motion.easing.Quadratic;
	
	import game.components.entity.character.animation.RigAnimation;
	import game.components.hit.Zone;
	import game.components.motion.FollowTarget;
	import game.components.timeline.Timeline;
	import game.data.TimedEvent;
	import game.data.WaveMotionData;
	import game.data.animation.Animation;
	import game.data.animation.entity.character.Proud;
	import game.data.animation.entity.character.SoarDown;
	import game.data.comm.PopResponse;
	import game.data.display.BitmapWrapper;
	import game.data.game.GameEvent;
	import game.scene.template.ItemGroup;
	import game.scenes.myth.mountOlympus3.MountOlympus3;
	import game.scenes.myth.shared.MythScene;
	import game.scenes.myth.shared.components.Cloud;
	import game.scenes.myth.shared.components.CloudMass;
	import game.scenes.myth.shared.components.ElectrifyComponent;
	import game.scenes.myth.shared.systems.CloudSystem;
	import game.scenes.myth.shared.systems.ElectrifySystem;
	import game.systems.SystemPriorities;
	import game.ui.popup.IslandEndingPopup;
	import game.util.CharUtils;
	import game.util.DisplayUtils;
	import game.util.EntityUtils;
	import game.util.GeomUtils;
	import game.util.MotionUtils;
	import game.util.PerformanceUtils;
	import game.util.PlatformUtils;
	import game.util.SceneUtil;
	import game.util.SkinUtils;
	
	public class MountOlympus2 extends MythScene
	{
		public function MountOlympus2()
		{
			super();
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{			
			super.groupPrefix = "scenes/myth/mountOlympus2/";
			
			super.init(container);
		}
		
		// initiate asset load of scene specific assets.
		override public function load():void
		{
			super.load();
		}
		
		// all assets ready
		override public function loaded():void
		{
			super.loaded();
			//			_events = events as MythEvents;
			_itemGroup = getGroupById( ItemGroup.GROUP_ID ) as ItemGroup;
			super.shellApi.eventTriggered.add(eventTriggers);
			zeus = getEntityById("zeus");
			athena = getEntityById("athena");
			setupLighting();
			
			if( !shellApi.checkEvent( GameEvent.GOT_ITEM + _events.MEDAL_MYTHOLOGY ))
			{
				if( shellApi.checkEvent( _events.RETURNED_ITEMS ))
				{
					SceneUtil.lockInput( this );
					talkToAthena();
				}
			}
		}
		
		// process incoming events
		private function eventTriggers( event:String, save:Boolean = true, init:Boolean = false, removeEvent:String = null ):void
		{
			switch( event )
			{
				case "look_player":
					SceneUtil.setCameraTarget( this, player );
					break;
				case _events.PLAYER_BECOME_GOD:
					equipTrident();
					break;
				case "getMedal":
					super.shellApi.eventTriggered.remove( eventTriggers );
					super.shellApi.getItem( _events.MEDAL_MYTHOLOGY );
					ItemGroup(super.getGroupById( ItemGroup.GROUP_ID )).showItem( _events.MEDAL_MYTHOLOGY, "", null, onMedalReceived );
					super.shellApi.triggerEvent( "victory" );
					//shellApi.completedIsland();
					break;
			}
		}
		
		
		private function onMedalReceived():void
		{
			CharUtils.setAnim( player, Proud );
			RigAnimation( CharUtils.getRigAnim( player )).ended.add( onCelebrateEnd );
		}
		
		private function onCelebrateEnd( anim:Animation = null ):void
		{		
			RigAnimation( CharUtils.getRigAnim( super.player) ).ended.remove( onCelebrateEnd );
			shellApi.completedIsland('', onCompletions);
		}

		private function onCompletions(response:PopResponse):void
		{
			SceneUtil.lockInput(this, false, false);
			var islandEndPopup:IslandEndingPopup = new IslandEndingPopup(this.overlayContainer)
			islandEndPopup.closeButtonInclude = true;
			this.addChildGroup( islandEndPopup );
		}
		
		private function talkToAthena( ...params ):void
		{
			SceneUtil.setCameraTarget(this,player);
			//			var dialog:Dialog = athena.get( Dialog );
			//			dialog.sayById( "victory" );
			if(athena!=null)
			{
				var interaction:Interaction = athena.get( Interaction );
				interaction.click.dispatch( athena );  // only works if click interaction is prepaird already
			}
		}
		
		
		/*******************************
		 * 
		 * 			  LIGHTS	
		 * 
		 *******************************/
		
		private function setupLighting():void
		{
			var clip:MovieClip = _hitContainer[ "overlay" ];
			var display:Display;
			var light:Entity;
			var number:int;
			var tween:Tween;
			var zone:Zone;
			
			if(shellApi.checkEvent(_events.RETURNED_ITEMS))
			{
				_hitContainer.removeChild( clip );
				
				for( number = 1; number <= totalLights; number++) 
				{		
					clip = _hitContainer[ "glow" + number ];
					_hitContainer.removeChild( clip );
				}
			}
				
			else
			{
				_hitContainer.setChildIndex( clip, _hitContainer.numChildren - 1 );
				var overlay:Entity = EntityUtils.createSpatialEntity( this, clip );
				overlay.add( new Id( "overlay" )).add( new Tween );
				
				for ( number = 1; number <= totalLights; number++) 
				{
					
					clip = _hitContainer[ "glow" + number ];
					_hitContainer.setChildIndex( clip, _hitContainer.numChildren - 1 );
					light = EntityUtils.createSpatialEntity( this, clip );
					light.add( new Id( "glow" + number ));
					display = light.get( Display );
					
					if( number <= triggeredLights )
					{
						light.add( new Tween());
						display.alpha = 0;
						zone = getEntityById( "lightZone" + number ).get( Zone );
						zone.entered.addOnce( Command.create( triggerLight, light ));
					}
						
					else if( number < totalLights )
					{ 
						light.add( new Tween());
						alphaDown( light );
					}
						
					else
					{
						display.alpha = 0;
						zeusSpotLight = light;
					} 			
				}
			}
		}
		
		private function triggerLight( zone:String, char:String, light:Entity ):void
		{
			alphaUp( light );
			lightsLeft--;
			
			if( lightsLeft <= 0 )
			{
				shellApi.triggerEvent( _events.ZEUS_APPEARS_THRONE, true );
				EntityUtils.position(zeus, 1278, 973);
				SceneUtil.addTimedEvent( this,new TimedEvent( 2, 1, showThrone ));
				SceneUtil.lockInput( this );
			}
			
			shellApi.triggerEvent("light_up_statue");
		}
		
		/*******************************
		 * 
		 * 	      TWEEN LIGHTS	
		 * 
		 *******************************/
		
		private function alphaDown( light:Entity ):void
		{
			var display:Display = light.get( Display );
			var tween:Tween = light.get( Tween );
			
			tween.to( display, 1, { alpha : .3, ease : Quadratic.easeInOut, onComplete : alphaUp, onCompleteParams : [ light ]});
		}
		
		private function alphaUp( light:Entity ):void
		{
			var display:Display = light.get( Display );
			var tween:Tween = light.get( Tween );
			
			tween.to( display, 1, { alpha : .94, ease : Quadratic.easeInOut, onComplete : alphaDown, onCompleteParams : [ light ]});
		}
		
		/*******************************
		 * 
		 * 		   ZEUS : PART 1	
		 * 
		 *******************************/
		
		private function showThrone():void
		{	
			showZeus();
			SceneUtil.setCameraTarget( this, zeus );
			SceneUtil.addTimedEvent( this, new TimedEvent( 1, 1, lightsOn ));
		}
		
		private function showZeus():void
		{
			shellApi.triggerEvent( "showZeus" );
			// do zeus's superman thing...
			var display:Display = zeus.get( Display );
			display.visible = false;
			CharUtils.setAnim( zeus, SoarDown );	
			
			var timeline:Timeline = zeus.get( Timeline );
			timeline.gotoAndStop( 9 );
			MotionUtils.addWaveMotion( zeus, new WaveMotionData( "y", 8, 0.05 ), this );
			electrifyZeus();
			
			var x1:Number = EntityUtils.getPosition(player).x;
			var x2:Number = EntityUtils.getPosition(zeus).x;
			
			if( x1 > x2 )
			{
				CharUtils.setDirection(zeus,true);
				CharUtils.setDirection(player,false);
			}
			else
			{
				CharUtils.setDirection(zeus,false);
				CharUtils.setDirection(player,true);
			}
		}
		
		
		private function electrifyZeus():void
		{
			addSystem(new ElectrifySystem(),SystemPriorities.update);
			var display:Display = zeus.get( Display );
			var electrify:ElectrifyComponent = new ElectrifyComponent();	
			
			// Add flashy filters to display
			if(!PlatformUtils.isMobileOS)
			{
				var colorFill:GlowFilter = new GlowFilter( 0xFFFFFF, 1, 100, 100, 1, 1, true );
				var colorGlow:GlowFilter = new GlowFilter( 0xFFFFFF, 1, 20, 20, 1, 1 );
				var whiteOutline:GlowFilter = new GlowFilter( 0xFFFFFF, 1, 8, 8, 1, 1, true );			
				var filters:Array = new Array( colorFill, whiteOutline, colorGlow );
				display.displayObject.filters = filters;		
			}
			
			// Electrify
			for( var number:int = 0; number < 10; number ++ )
			{
				var sprite:Sprite = new Sprite();;
				var startX:Number = Math.random() * 120 - 60;
				var startY:Number = Math.random() * 280 - 140;				
				sprite.graphics.lineStyle( 1, 0xFFFFFF );
				sprite.graphics.moveTo( startX, startY );
				electrify.sparks.push( sprite );
				electrify.lastX.push( startX );
				electrify.lastY.push( startY );
				electrify.childNum.push( display.displayObject.numChildren );
				display.displayObject.addChildAt( sprite, display.displayObject.numChildren );
			}			
			zeus.add( electrify );
		}
		
		private function lightsOn():void
		{
			
			var display:Display = zeus.get( Display );
			display.visible = true;
			DisplayUtils.moveToTop( display.displayObject );
			shellApi.triggerEvent("zeus_boom");
			
			display = zeusSpotLight.get( Display );
			display.alpha = 1;
		}
		
		private function equipTrident():void
		{
			_itemGroup.takeItem(_events.POSEIDON_TRIDENT,"player", "", null, equipCrown );
			SkinUtils.setSkinPart( player, SkinUtils.ITEM,"poseidon",false);
		}
		
		private function equipCrown():void
		{
			_itemGroup.takeItem(_events.HADES_CROWN,"player" );
			SkinUtils.setSkinPart( player, SkinUtils.HAIR, "hades",false);
			
			var overlay:Entity = getEntityById("overlay");
			var tween:Tween = overlay.get( Tween );
			var display:Display = overlay.get( Display );
			tween.to( display, 1, { alpha : 0, onComplete : playerTransform });
		}
		
		private function playerTransform():void
		{
			CharUtils.triggerSpecialAbility( player );
			DisplayUtils.moveToTop( player.get( Display ).displayObject );
			makeClouds();
		}
		
		private function makeClouds():void
		{
			var playerSpatial:Spatial = player.get( Spatial );
			
			addSystem( new CloudSystem( true ), SystemPriorities.move );
			var entity:Entity;
			var followTarget:FollowTarget;
			var spatial:Spatial;
			var cloud:Cloud;
			var display:Display;
			
			var randX:Number = 0;
			var randY:Number = 0;
			
			var sprite:Sprite;
			var clip:MovieClip = _hitContainer[ "cloud" ];
			var bitmapData:BitmapData;
			var wrapper:BitmapWrapper = this.convertToBitmapSprite( clip, null, false );
			
			var displayObjectBounds:Rectangle = clip.getBounds( clip );
			var offsetMatrix : Matrix = new Matrix( 1, 0, 0, 1, displayObjectBounds.left, displayObjectBounds.top );
			var bitmap:Bitmap;
			var swirlOffset:Number;
			var cloudMass:CloudMass = new CloudMass();
			var number:int;
			
			var maxClouds:int = 20;
			if( PerformanceUtils.qualityLevel < PerformanceUtils.QUALITY_MEDIUM )
			{
				maxClouds = 5;
			}
			
			for( number = 0; number < maxClouds; number++ )
			{
				sprite = new Sprite();
				bitmapData = new BitmapData( clip.width, clip.height, true, 0x000000 );
				bitmapData.draw( wrapper.data );
				bitmap = new Bitmap( bitmapData, "auto", true );
				
				bitmap.transform.matrix = offsetMatrix;
				sprite.addChild( bitmap );
				
				entity = EntityUtils.createMovingEntity( this, sprite, _hitContainer );
				
				entity.add( new Id( "cloud" +  number ));
				spatial = entity.get( Spatial );
				display = entity.get( Display );
				cloud = new Cloud();
				followTarget = new FollowTarget( player.get( Spatial ));
				entity.add( cloud ).add( followTarget );
				
				cloud.state = cloud.GATHER;
				cloud.attached = true;
				display.alpha = 1;
				MotionUtils.zeroMotion( entity );
				randX = GeomUtils.randomInRange( playerSpatial.x - 30, playerSpatial.x + 30 ) - 30;
				randY = GeomUtils.randomInRange( playerSpatial.y - 10, playerSpatial.y + 10 ) + 10;
				
				spatial.x = randX;
				spatial.y = randY;
				
				cloudMass.clouds.push( cloud );
				
				swirlOffset = GeomUtils.randomInRange( 1.0, 1.6 );
				MotionUtils.addWaveMotion(entity, new WaveMotionData("x", (( Math.random() * 3 ) + 3 ) * swirlOffset, .2),this);
				
				entity.add( new SpatialAddition());
			}
			
			player.add( cloudMass );
			
			SceneUtil.addTimedEvent( this, new TimedEvent( 1, 1, nextScene ));
		}
		
		private function nextScene():void
		{
			super.shellApi.loadScene( MountOlympus3 );
		}
		
		
		private var _itemGroup:ItemGroup;
		private var totalLights:int = 7;
		private var triggeredLights:int = 4;
		private var lightsLeft:int = 4;
		private var zeusSpotLight:Entity;
		private var zeus:Entity;
		private var athena:Entity;
	}
}