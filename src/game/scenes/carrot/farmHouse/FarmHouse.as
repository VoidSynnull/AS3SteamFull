package game.scenes.carrot.farmHouse
{
	import com.greensock.TweenLite;
	
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.geom.Point;
	
	import ash.core.Entity;
	
	import engine.components.Audio;
	import engine.components.Display;
	import engine.components.Interaction;
	import engine.components.Spatial;
	import engine.managers.SoundManager;
	
	import game.components.entity.Children;
	import game.components.entity.DepthChecker;
	import game.components.entity.Dialog;
	import game.components.entity.character.Npc;
	import game.components.motion.MotionControl;
	import game.components.motion.Threshold;
	import game.components.scene.SceneInteraction;
	import game.components.timeline.Timeline;
	import game.creators.entity.EmitterCreator;
	import game.creators.ui.ToolTipCreator;
	import game.data.TimedEvent;
	import game.data.animation.entity.character.Drink;
	import game.data.animation.entity.character.Place;
	import game.data.scene.characterDialog.DialogData;
	import game.scene.template.AudioGroup;
	import game.scene.template.PlatformerGameScene;
	import game.scenes.carrot.CarrotEvents;
	import game.systems.motion.ThresholdSystem;
	import game.util.CharUtils;
	import game.util.EntityUtils;
	import game.util.SceneUtil;
	
	public class FarmHouse extends PlatformerGameScene
	{
		public function FarmHouse()
		{
			super();
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{			
			super.groupPrefix = "scenes/carrot/farmHouse/";
			super.init(container);
		}
				
		// initiate asset load of scene specific assets.
		override public function load():void
		{
			super.load();
		}
		
		override public function destroy():void
		{
			_cat = null;
			super.destroy();
		}
		
		// all assets ready
		override public function loaded():void
		{
			super.loaded();
			
			_events = super.events as CarrotEvents;
			
			super.addSystem( new ThresholdSystem());
			var sceneInteraction:SceneInteraction;
			var number:int;
			
			for( number = 1; number < 3; number ++ )
			{
				sceneInteraction = getEntityById( "interaction" + number ).get( SceneInteraction );
				sceneInteraction.offsetY = 40;
				sceneInteraction.reached.add(sceneInteractionTriggered);
			}
			
			if( !super.shellApi.checkEvent( _events.CAT_RETURNED ))
			{
				if(super.shellApi.checkEvent(_events.MILK_PLACED))
				{
					super._hitContainer["bowlFull"].visible = true;
					super._hitContainer["bowlFull"].alpha = 1;
				}
				else
				{
					super._hitContainer["bowlFull"].visible = false;
				}
				
				
				if(super.shellApi.checkHasItem(_events.BOWL_OF_MILK))
				{
					placeBowlOfMilk();
				}
				
				_cat = super.getEntityById("cat");
				ToolTipCreator.removeFromEntity(_cat);

				var audioGroup:AudioGroup = super.getGroupById("audioGroup") as AudioGroup;
				audioGroup.addAudioToEntity(_cat);
				
				Spatial( _cat.get( Spatial )).scaleX *= -1;
				Display( _cat.get( Display )).moveToBack();
				Display( _cat.get( Display )).visible = false;
				
				var interaction:Interaction = _cat.get(Interaction);
				if( interaction )
				{
					interaction.click.removeAll();
					interaction.click.add(catClicked);
				}
				
				if(super.shellApi.checkEvent( _events.CAT_FOLLOWING))
				{
					Display( _cat.get( Display )).visible = true;
					EntityUtils.positionByEntity(_cat, shellApi.player);
					SceneUtil.addTimedEvent( this, new TimedEvent(( Math.random() * 15 + 5 ), 1, catPurr ));
					CharUtils.followEntity(_cat, shellApi.player);
					_cat.add( new DepthChecker() );
					Npc( _cat.get( Npc )).ignoreDepth = false;
				}
				else
				{
					var children:Children = _cat.get(Children);	
					_toolTip = children.children[0];
					this.removeEntity(children.children[0]);
					children.children.splice(0, 1);
					
					SceneUtil.addTimedEvent( this, new TimedEvent(( Math.random() * 15 + 5 ), 1, catMeow ));
				}
			}
		}
		
		private function catPurr():void
		{
			super.shellApi.triggerEvent( _events.CAT_PURR );
			SceneUtil.addTimedEvent( this, new TimedEvent(( Math.random() * 15 + 5 ), 1, catPurr ));
		}
		
		private function catMeow():void
		{
			if( !super.shellApi.checkEvent( _events.CAT_FOLLOWING ))
			{
				super.shellApi.triggerEvent( _events.CAT_MEOW );
				SceneUtil.addTimedEvent( this, new TimedEvent(( Math.random() * 15 + 5 ), 1, catMeow ));
			}
		}
				
		private function sceneInteractionTriggered(character:Entity, interaction:Entity):void
		{
			var faucet:MovieClip = MovieClip((interaction.get(Display)).displayObject);
			var rotation:Number = Math.floor(Math.random() * 600) + 400;
			
			
			TweenLite.to(faucet.handle, 1, { rotation : rotation });
			TweenLite.to(faucet.shadow, 1, { rotation : rotation });
			
			super.shellApi.triggerEvent( _events.SHOWER_KNOB_TURNED );
			
			if(!_faucetOn)
			{
				_faucetOn = true;
				
				for( var i:int = 1; i < 3; i++ )
				{
					Display( super.getEntityById( "interaction" + i ).get( Display )).moveToBack();
				}
								
				var emitter:Shower = new Shower(); 
				_shower = EmitterCreator.create(this, super._hitContainer[ "showerEmpty" ], emitter ); 
				emitter.init();
					
				if( !super.shellApi.checkEvent( _events.CAT_RETURNED ))
				{
					if( !super.shellApi.checkEvent( _events.CAT_FOLLOWING ))	
					{
						var catInteraction:Interaction = _cat.get(Interaction);
						
						// Add tooltip back in
						var children:Children = _cat.get(Children);	
						children.children.push(_toolTip);
						this.addEntity(_toolTip);
						
						super.shellApi.triggerEvent(_events.SHOWER_STARTED);
	
						Display( _cat.get( Display )).visible = true;
						CharUtils.setDirection( _cat, true );
		
						var path:Vector.<Point> = new Vector.<Point>();
						path.push( new Point( 245, 260 ));
						path.push( new Point( 385, 370 ));
						path.push( new Point( 600, 452 ));
											
						if (super.shellApi.checkEvent(_events.MILK_PLACED))
						{
							path.push( new Point( 970, 452 ));
							path.push( new Point( 1300, 452 ));
							path.push( new Point( 1256, 969 ));
							path.push( new Point( 645, 969 ));
				
							CharUtils.followPath( _cat, path, catReachedBowl );
							SceneUtil.lockInput( this, true, false );
							SceneUtil.setCameraTarget( this, _cat );
						}
						else
						{
							path.push( new Point( 850, 375 ));
							path.push( new Point( 980, 220 ));
							
							CharUtils.followPath( _cat, path );
						}
					}
				}
			}
		}
		
		private function catReachedBowl(entity:Entity):void
		{
			CharUtils.setAnim(entity, Drink);
			
			var timeline:Timeline = CharUtils.getTimeline( _cat );
			timeline.labelReached.add( onCatAnimLabel );
			super.shellApi.triggerEvent( _events.CAT_DRINK );
		}
		
		private function onCatAnimLabel( label:String ):void
		{
			var audio:Audio = _cat.get( Audio );
			if( label == "ending" )
			{
				var timeline:Timeline = _cat.get( Timeline );
				timeline.labelReached.removeAll();
				
				audio.stop( SoundManager.EFFECTS_PATH + DRINKING );
				super.shellApi.triggerEvent( _events.MILK_GIVEN, true );
				Dialog( _cat.get( Dialog )).complete.addOnce( catDialogComplete );
			}		
		}
		
		private function catDialogComplete(dialog:DialogData):void
		{
			super.shellApi.camera.target = super.shellApi.player.get(Spatial);
			MotionControl(super.shellApi.player.get(MotionControl)).lockInput = false;
			
			SceneUtil.lockInput( this, false, false );
			
			var player:Entity = super.player;
			
			var threshold:Threshold = new Threshold( "y", ">" );
			threshold.threshold = 950;
			threshold.entered.addOnce( catFollow );
		
			super.player.add( threshold );
		}
		
		private function catFollow():void
		{
			CharUtils.followEntity( _cat, shellApi.player, new Point(300, 200) );
			
			Dialog( player.get( Dialog )).sayById( "cat_following" );
			SceneUtil.addTimedEvent( this, new TimedEvent( Math.random() * 15, 1, catPurr ));
		}
		
		private function catClicked(entity:Entity):void
		{
			if ( !super.shellApi.checkEvent(_events.CAT_FOLLOWING) )
			{
				super.shellApi.triggerEvent(_events.CAT_HIDING);
			}
			else
			{
				super.shellApi.triggerEvent( _events.CAT_FOLLOWING );
			}
		}
		
		private function placeBowlOfMilk():void
		{
			CharUtils.moveToTarget(super.shellApi.player, 610, 969, true, playerReachedBowl);
		}
		
		private function playerReachedBowl(entity:Entity):void
		{
			CharUtils.setAnim(super.player, Place);
			
			var timeline:Timeline = CharUtils.getTimeline( super.player );
			timeline.labelReached.add( onPlayerAnimeLabel );
		}
		
		public function onPlayerAnimeLabel( label:String ):void
		{
			if( label == "trigger" )
			{
				super.shellApi.triggerEvent( _events.PLACE_BOWL );
				var timeline:Timeline = super.player.get( Timeline );
				timeline.labelReached.removeAll();
				
				var bowl:Entity = EntityUtils.createSpatialEntity( this, super._hitContainer[ "bowlFull" ] );
				
				super.shellApi.removeItem(_events.BOWL_OF_MILK);
				super.shellApi.completeEvent(_events.MILK_PLACED);
				MotionControl(super.shellApi.player.get(MotionControl)).lockInput = false;
			}
		}

		private const DRINKING:String = "cat_sipping_01_L.mp3";
		private var _faucetOn:Boolean = false;
		private var _toolTip:Entity;
		private var _shower:Entity;
		private var _cat:Entity;
		private var _events:CarrotEvents;
	}
}