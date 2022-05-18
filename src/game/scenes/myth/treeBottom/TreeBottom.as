package game.scenes.myth.treeBottom
{
	import com.greensock.easing.Quad;
	import com.greensock.easing.Sine;
	
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.filters.GlowFilter;
	import flash.geom.Point;
	
	import ash.core.Entity;
	
	import engine.components.Audio;
	import engine.components.Display;
	import engine.components.Id;
	import engine.components.Interaction;
	import engine.components.Motion;
	import engine.components.Spatial;
	import engine.components.SpatialAddition;
	import engine.components.Tween;
	import engine.creators.InteractionCreator;
	import engine.util.Command;
	
	import game.components.entity.Dialog;
	import game.components.entity.Sleep;
	import game.components.entity.character.Character;
	import game.components.hit.Zone;
	import game.components.motion.Edge;
	import game.components.motion.ScaleTarget;
	import game.components.motion.WaveMotion;
	import game.components.scene.SceneInteraction;
	import game.components.timeline.Timeline;
	import game.creators.ui.ToolTipCreator;
	import game.data.TimedEvent;
	import game.data.WaveMotionData;
	import game.data.animation.entity.character.Laugh;
	import game.data.animation.entity.character.Salute;
	import game.data.animation.entity.character.Stand;
	import game.data.game.GameEvent;
	import game.scene.template.AudioGroup;
	import game.scenes.myth.shared.Athena;
	import game.scenes.myth.shared.MythScene;
	import game.scenes.myth.shared.components.ElectrifyComponent;
	import game.scenes.myth.shared.systems.ElectrifySystem;
	import game.scenes.myth.treeBottom.popups.Scramble;
	import game.components.entity.OriginPoint;
	import game.systems.motion.ScaleSystem;
	import game.util.CharUtils;
	import game.util.EntityUtils;
	import game.util.PerformanceUtils;
	import game.util.SceneUtil;
		
	
	public class TreeBottom extends MythScene
	{
		public function TreeBottom()
		{
			super();
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{			
			super.groupPrefix = "scenes/myth/treeBottom/";

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
			_openAthena = false;
			
			oldAthena = getEntityById("crone");
			athena = getEntityById("athena");
			zeus = getEntityById("zeus");
			
			super.shellApi.eventTriggered.add( eventTriggers );
			super.addSystem( new ScaleSystem());
			super.addSystem(new ElectrifySystem());
			
			var clip:MovieClip = _hitContainer[ "oliveTarget" ];
		
			if( super.shellApi.checkEvent( _events.ZEUS_APPEARS_TREE ))
			{
				var entity:Entity = EntityUtils.createSpatialEntity( this, clip );
				var sleep:Sleep = new Sleep();
				var display:Display = entity.get( Display );
				entity.add( new Id( "oliveTarget" )).add( sleep );
				
				if( !shellApi.checkEvent( _events.ATHENA_TRANSFORM ))
				{
					sleep.sleeping = true;
					display.alpha = 0;
					
					SceneUtil.lockInput( this );
					sleep = athena.get( Sleep );
					if( !sleep )
					{
						sleep = new Sleep();
						athena.add( sleep );
					}
					sleep.sleeping = false;
					sleep.ignoreOffscreenSleep = true;
					
					sleep = oldAthena.get( Sleep );
					if( !sleep )
					{
						sleep = new Sleep();
						oldAthena.add( sleep );
					}
					sleep.sleeping = false;
					sleep.ignoreOffscreenSleep = true;
					
					removeEntity( zeus );
					
					CharUtils.setDirection(oldAthena,false);
					EntityUtils.getDisplay(athena).alpha = 0;
				}
				else
				{
					InteractionCreator.addToEntity( entity, [ InteractionCreator.CLICK ]);
					var interaction:Interaction = entity.get( Interaction );
					interaction.click.add( athenaPopup );
					ToolTipCreator.addToEntity( entity );
				}
			}
			
			else
			{
			//	sleep.sleeping = true;
				_hitContainer.removeChild( clip );
			}
			
			super.loaded();
			setInitialEvents();			
			
			setupButterflies();
			
			setupSatyrTalkZone();
		}
		
		/**
		 * 
		 * CHARACETER DIALOGS
		 * 
		 */
		
		override protected function addCharacterDialog(container:Sprite):void
		{
			setupTalkingStatues();
			super.addCharacterDialog(container);
		}
		
		private function setupTalkingStatues():void
		{
			var clip:MovieClip;
			var dialog:Dialog;
			var entity:Entity;
			var sceneInteraction:SceneInteraction;
			
			// dialog for talking statues
			for ( var i:int = 1; i <= 2; i++ ) 
			{
				clip = _hitContainer[ "customDialog" + i ];
				entity = EntityUtils.createSpatialEntity( this, clip );
				
				dialog = new Dialog();
				dialog.faceSpeaker = true;
				dialog.dialogPositionPercents = new Point( 0, .5 );				
				entity.add( dialog );
				entity.add( new Id( "customDialog" + i ));
				
				entity.add( new Edge( 50, 50, 50, 80 ));
				entity.add( new Character());				
				
				InteractionCreator.addToEntity( entity, [ InteractionCreator.CLICK ]);
				sceneInteraction = new SceneInteraction();
				sceneInteraction.offsetX = 70;
				sceneInteraction.offsetY = 150;
				entity.add( sceneInteraction );		
				
				ToolTipCreator.addToEntity( entity );
			}
		}
		
		/**
		 * 
		 * ATHENA POPUP
		 * 
		 */
		private function athenaPopup( interactionEntity:Entity ):void
		{
			if( !_openAthena )
			{
				_openAthena = true;
				var popup:Athena = super.addChildGroup( new Athena( super.overlayContainer )) as Athena;
				popup.closeClicked.add( resetPopup );
				popup.id = "athena";
			}
		}
		
		private function resetPopup( ...args ):void
		{
			_openAthena = false;
		}
		
		// process incoming events
		private function eventTriggers(event:String, save:Boolean = true, init:Boolean = false, removeEvent:String = null):void
		{
			if(event == "item_puzzle_start")
			{
				scramblePopup();
			}
			
			else if(event == "athena_olives")
			{
				var entity:Entity = super.getEntityById( "oliveTarget" );
				var tween:Tween = new Tween();
				var spatial:Spatial = entity.get( Spatial );
				var display:Display = entity.get( Display );
				
				tween.from( spatial, 2, { scaleX : 0, scaleY : 0, onComplete : turnOnOlive });
				tween.to( display, 1, { alpha : 1 });
				entity.add( tween );
			}
			else if(event == "zeus_appears_steal")
			{
				if( !zeus_stole )
				{
					zeus_stole = true;
					EntityUtils.getDisplay(zeus).alpha = 0.0;
					showZeus();
				}
			}
			else if(event == "zeus_escaped")
			{
				zeusEscaped();
			}
			else if( event == "hurry_up" )
			{
				SceneUtil.lockInput( this, false );
			}
		}
		
		private function scramblePopup():void
		{
			SceneUtil.lockInput( this, false );
			var popup:Scramble = super.addChildGroup( new Scramble( super.overlayContainer )) as Scramble;
			popup.id = "scramble";			
			popup.complete.add( Command.create( completeScramble, popup ));
		}
		
		private function completeScramble( popup:Scramble ):void
		{
			popup.close();
//			CharUtils.lockControls( player );
			var interaction:Interaction = athena.get(Interaction);
			interaction.click.remove( lockUp );
			SceneUtil.lockInput( this );
			shellApi.triggerEvent("item_puzzle_complete",true);
		}
		
		/**
		 * 
		 * WALLED OFF ZONE
		 * 
		 */
		private function setupSatyrTalkZone():void
		{
			if( !super.shellApi.checkItemEvent( _events.ZEUS_SCROLL ))
			{
				var zoneEnt:Entity = getEntityById("satyrZone");
				var zone:Zone = zoneEnt.get(Zone);
				zone.entered.add(satyrTalk);
			}else
			{
				removeEntity(getEntityById( "satyr" ));
				removeEntity(getEntityById( "satyrZone" ));
			}

		}
		
		private function satyrTalk(zone:String, char:String):void
		{
			satyr = getEntityById( "satyr" );
			if(satyr!=null)
			{
//				lock();
				CharUtils.lockControls( player )
				var interaction:Interaction = satyr.get(Interaction);
				interaction.click.dispatch(satyr);  // only works if click interaction is prepaird already
				Dialog( satyr.get( Dialog )).complete.add( unlock );
			}
		}
		
		/**
		 * 
		 * ZEUS
		 * 
		 */
		
		private function showZeus():void
		{
			//flash, awaken!
			EntityUtils.getDisplay(zeus).alpha = 1.0;
			setSleep( zeus, false );
			
			var spatial:Spatial = zeus.get( Spatial );
			var playerSpatial:Spatial = player.get( Spatial );
			
			var deltaX:Number = playerSpatial.x - spatial.x;
			
			SceneUtil.setCameraPoint( this, spatial.x + ( deltaX / 2 ), spatial.y );
			
			shellApi.triggerEvent("zeus_appears_sound");
//			// animate zeus
			var anims:Vector.<Class> = new Vector.<Class>();
			anims.push(Laugh,Salute,Stand);
			CharUtils.setAnimSequence(zeus,anims,false);
			CharUtils.getTimeline(zeus).handleLabel("stop",zeusStealItems,true);					
			CharUtils.setDirection(player,false);
			
			super.createLightningCover();
		}
				
		private function zeusStealItems():void
		{
			_flashing = false;
			CharUtils.setAnim( zeus, Salute );
			stolenItems = new Vector.<Entity>();
			shellApi.triggerEvent("zeus_steal_sound");
			for (var i:int = 0; i < 5; i++) 
			{
				var item:Entity = EntityUtils.createSpatialEntity(this, _hitContainer["item"+i]);
				stolenItems.unshift( item );
				var tween:Tween =  new Tween();
				item.add(tween);
			}
			stealItems(0);
		}
		
		// iterate items flying to zues
		private function stealItems(index:int):void
		{
			if(index < stolenItems.length)
			{
				var item:Entity = stolenItems[index];
				var start:Point = EntityUtils.getPosition(player);
				var end:Point = EntityUtils.getPosition(zeus);			
				EntityUtils.position(item, start.x, start.y);	
				
				index++;
				var steal:Function = Command.create(stealItems, index);
				item.get(Tween).to(item.get(Spatial), 0.55, {x:end.x, y:end.y, ease:Quad.easeInOut, onComplete:itemStolen, onCompleteParams: [ item, index ]});
			//	SceneUtil.addTimedEvent(this,new TimedEvent(0.22,1,steal,true));
			}
			else
			{
				shellApi.triggerEvent( "zeus_steal_finished",true);
			}
		}
		
		private function itemStolen( item:Entity, index:int ):void
		{
			removeEntity(item,true);
			stealItems( index );
		}
		
		private function zeusEscaped():void
		{
			CharUtils.setAnim( zeus, Laugh );
			
			var timeline:Timeline = zeus.get( Timeline );
			timeline.labelReached.add( zeusListener );//handleLabel( "ending", zeusLeft );
			shellApi.triggerEvent("zeus_appears_sound");
		}
		
		
		private function zeusListener( label:String ):void
		{
			if( label == "ending" )
			{
				super.createLightningCover();
			}
			else if( label == "stand" )
			{
				removeEntity( zeus, true );
				
				var playerSpatial:Spatial = player.get( Spatial );
				var athenaSpatial:Spatial = athena.get( Spatial );
				
				if( playerSpatial.x > athenaSpatial.x )
				{
					CharUtils.setDirection( player, false );
					CharUtils.setDirection( athena, true );
				}
				else
				{
					CharUtils.setDirection( player, true );
					CharUtils.setDirection( athena, false );
				}
				var dialog:Dialog = athena.get( Dialog );
				dialog.sayById( "zeus_escaped" );
				
				SceneUtil.setCameraTarget( this, player );
				_flashing = false;
			}
		}
		
		// initiate event specific entities
		private function setInitialEvents():void
		{			
			if(shellApi.checkEvent("zeus_steal_finished"))
			{
				removeEntity(oldAthena);
				removeEntity(zeus);
//				removeEntity(lightning);
			}
			else if(shellApi.checkEvent("got_all_items"))
			{
				// zeus steals your stuff event
				shellApi.triggerEvent("athena_all_items",true);
				removeEntity(oldAthena);			
				setSleep(zeus,true);
				CharUtils.setScale(athena,0.5);	
				
//				var sceneInteraction:SceneInteraction = athena.get(SceneInteraction);
//				sceneInteraction.offsetX = 70;
				
				var interaction:Interaction = athena.get(Interaction);
				interaction.click.add( lockUp );
				interaction.click.dispatch(athena);
			}
			else if(shellApi.checkEvent(_events.ATHENA_TRANSFORM))
			{
				// remove everyone if scene is visited after initial talk with athena
				removeEntity(oldAthena);
				removeEntity(athena);
				removeEntity(zeus);
//				removeEntity(lightning);
			}
			else if( super.shellApi.checkEvent( GameEvent.HAS_ITEM + _events.ZEUS_SCROLL ))
			{
				if(! super.shellApi.checkEvent( _events.ATHENA_TRANSFORM ))
				{
					var display:Display = athena.get( Display );
					display.alpha = 0;
					_audioGroup.addAudioToEntity( athena );
					shellApi.triggerEvent("athena_appear");
					SceneUtil.setCameraTarget(this,athena);
					SceneUtil.addTimedEvent(this,new TimedEvent(0.8,1,athenaTransform));
				}
			}
			else{
				setSleep(athena,true);
				setSleep(zeus,true);
				// lock sphinx door
				setSleep(getEntityById("doorSphinx"),true);
				SceneUtil.lockInput( this, false, false );
			}
		}
		
		private function lockUp( entity:Entity ):void
		{
			SceneUtil.lockInput( this );	
		}
		
		private function turnOnOlive():void
		{
			var entity:Entity = super.getEntityById( "oliveTarget" );
			var sleep:Sleep = entity.get( Sleep );
			sleep.sleeping = false;
			
			InteractionCreator.addToEntity( entity, [ InteractionCreator.CLICK ]);
			var interaction:Interaction = entity.get( Interaction );
			interaction.click.add( athenaPopup );
			ToolTipCreator.addToEntity( entity );
		}
		
		private function athenaTransform():void
		{			
			var scaleTarget:ScaleTarget = new ScaleTarget(.55);
			athena.add(scaleTarget);
			oldAthena.add(scaleTarget);	
			if( PerformanceUtils.determineQualityLevel() > PerformanceUtils.QUALITY_MEDIUM )
			{
				electrifyChar(athena);
				electrifyChar(oldAthena);	
			}
			CharUtils.setAnim( athena, Salute);
			CharUtils.setAnim(oldAthena,Salute);
			var timeline:Timeline = athena.get( Timeline );
			timeline.handleLabel("stop", talkToAthena);				
			var tweenEnt:Entity = new Entity();
			var tween:Tween = new Tween();
			tweenEnt.add(tween);
			addEntity(tweenEnt);			
			tween.to(EntityUtils.getDisplay(athena), 1.5,{alpha:1});
			tween.to(EntityUtils.getDisplay(oldAthena), 1.5,{alpha:0, onComplete:tranformFinished});	
			var audio:Audio = athena.get( Audio );
			audio.playCurrentAction( TRANSFORM );
		}
		
		private function tranformFinished():void
		{
			removeEntity(oldAthena, true);
			removeElectrify(athena);		
			
			ToolTipCreator.addToEntity( athena );
			shellApi.triggerEvent( _events.ATHENA_TRANSFORM, true);
		}
		
		
		
		
		// put electric effect on charadters
		private function electrifyChar(char:Entity):void
		{
			this.groupReady();	// dispatch that popup is now ready
			var display:Display = char.get( Display );
			var electrify:ElectrifyComponent = new ElectrifyComponent();
			// Add flashy filters to her display
			var colorFill:GlowFilter = new GlowFilter( 0xFFFFFF, 1, 100, 100, 1, 1, true );
			var colorGlow:GlowFilter = new GlowFilter( 0xFFFFFF, 1, 20, 20, 1, 1 );
			var whiteOutline:GlowFilter = new GlowFilter( 0xFFFFFF, 1, 8, 8, 1, 1, true );			
			var filters:Array = new Array( colorFill, whiteOutline, colorGlow );
			display.displayObject.filters = filters;			
			// Electrify athena
			for( var number:int = 0; number < 10; number ++ )
			{
				var sprite:Sprite = new Sprite();
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
			char.add( electrify );
		}
		
		private function removeElectrify(char:Entity):void{
			// kill glowing and sparks
			var electrify:ElectrifyComponent = char.get(ElectrifyComponent);
			if(electrify != null){
				var displayObj:DisplayObjectContainer = EntityUtils.getDisplayObject(char);
				displayObj.filters = new Array();
				// remove spark childern
				for( var i:int = 0; i < electrify.sparks.length; i++ )
				{
					displayObj.removeChild(electrify.sparks[i]);
				}
				char.remove(ElectrifyComponent);
			}
		}
		
		
		
		private function talkToAthena(...params):void
		{
			SceneUtil.setCameraTarget(this,player);
			AnimFix();
			if(athena!=null)
			{				
				var interaction:Interaction = athena.get(Interaction);
				interaction.click.dispatch(athena);  // only works if click interaction is prepaird already

			}
			SceneUtil.lockInput( this, false );
			Dialog(athena.get(Dialog)).complete.add(AnimFix);
//			Dialog( athena.get( Dialog )).complete.add( unlock );
		}
		
		// TODO: remove when animations comming back randomly is fixed
		private function AnimFix(...p):void
		{
			CharUtils.setAnim(athena,Stand,false,0,0,false);
		}
		
		private function setupButterflies():void 
		{			
			for ( var i:int = 0; i < 2; i ++ )
			{
				var tween:Tween = new Tween();
				var butterfly:Entity = EntityUtils.createMovingEntity( this, super._hitContainer[ "b" + ( i + 1 )]);
				var spatial:Spatial = butterfly.get( Spatial );
				var origin:OriginPoint = new OriginPoint( spatial.x, spatial.y );
				butterfly.add( tween ).add( origin).add( new SpatialAddition() );				
				moveButterfly( butterfly );
			}
		}
		
		private function moveButterfly( butterfly:Entity ):void 
		{
			var spatial:Spatial = butterfly.get( Spatial );
			var motion:Motion = butterfly.get( Motion );
			var origin:OriginPoint = butterfly.get( OriginPoint );
			var tween:Tween = butterfly.get( Tween );
			var wave:WaveMotion = new WaveMotion();
			wave.add( new WaveMotionData( "x", Math.random() * 15, Math.random() / 10 ));
			wave.add( new WaveMotionData( "y", Math.random() * 15, Math.random() / 10 ));			
			var goalX:Number = ( Math.random() * 200 ) + origin.x - 100;
			var goalY:Number = ( Math.random() * 200 ) + origin.y - 100;
			var duration:Number = ( Math.random() * 3 ) +1; 					
			butterfly.add( wave );						
			tween.to( spatial, duration, { x: goalX,y: goalY, ease:Sine.easeInOut,onComplete: moveButterfly,onCompleteParams:[ butterfly ]}); 	
		}
		
		private function setSleep( entity:Entity, sleeping:Boolean):void
		{
			var sleep:Sleep = entity.get(Sleep);
			if(sleep != null){
				sleep.sleeping = sleeping;
				sleep.ignoreOffscreenSleep = sleeping;
				entity.ignoreGroupPause = sleeping;			
			}
		}
		
		private function unlock(...args):void
		{
			CharUtils.lockControls( player, false, false );
		}
		
		private var athena:Entity;
		private var zeus:Entity;
		private var satyr:Entity;
		private var oldAthena:Entity;
		private var olives:Entity;
		private var zeus_stole:Boolean = false;
//		private var lightning:Entity;
		private var stolenItems:Vector.<Entity>;
		
		private var _openAthena:Boolean;
		private static const TRANSFORM:String =		"transform";
	}
}