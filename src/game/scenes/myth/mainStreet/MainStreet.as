package game.scenes.myth.mainStreet
{
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Interaction;
	import engine.components.Motion;
	import engine.components.Spatial;
	import engine.components.Tween;
	import engine.creators.InteractionCreator;
	import engine.group.TransportGroup;
	import engine.util.Command;
	
	import fl.transitions.easing.None;
	
	import game.components.entity.Dialog;
	import game.components.hit.Door;
	import game.components.motion.Threshold;
	import game.components.scene.SceneInteraction;
	import game.components.specialAbility.SpecialAbilityControl;
	import game.components.timeline.Timeline;
	import game.creators.ui.ToolTipCreator;
	import game.data.TimedEvent;
	import game.data.animation.entity.character.Attack;
	import game.data.character.LookAspectData;
	import game.data.character.LookData;
	import game.data.display.BitmapWrapper;
	import game.data.game.GameEvent;
	import game.data.scene.characterDialog.DialogData;
	import game.data.specialAbility.SpecialAbilityData;
	import game.data.ui.ToolTipType;
	import game.scene.template.PlatformerGameScene;
	import game.scene.template.ads.AdBlimpGroup;
	import game.scenes.custom.AdMiniBillboard;
	import game.scenes.myth.MythEvents;
	import game.scenes.myth.shared.abilities.Electrify;
	import game.scenes.myth.shared.abilities.Grow;
	import game.systems.SystemPriorities;
	import game.systems.motion.ThresholdSystem;
	import game.util.CharUtils;
	import game.util.EntityUtils;
	import game.util.PerformanceUtils;
	import game.util.PlatformUtils;
	import game.util.SceneUtil;
	import game.util.SkinUtils;
	import game.util.TimelineUtils;
			
	public class MainStreet extends PlatformerGameScene
	{
		public function MainStreet()
		{
			super();
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{			
			super.groupPrefix = "scenes/myth/mainStreet/";
			
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
			if( PlatformUtils.isMobileOS )
			{
				super.removeEntity( getEntityById( "doorMidasGym" ));	
			}
			_events = super.events as MythEvents;
			
			// tool tip on rope
			var rope:Entity = EntityUtils.createSpatialEntity(super, super.hitContainer["climb1"]);
			rope.get(Display).alpha = 0;
			// tool tip text (blank if blimp takeover)
			var toolTipText:String = (super.getGroupById(AdBlimpGroup.GROUP_ID) == null) ? "TRAVEL" : "";			
			ToolTipCreator.addToEntity(rope,ToolTipType.EXIT_UP, toolTipText);
			// rope behavior
			var interaction:Interaction = InteractionCreator.addToEntity(rope, [InteractionCreator.CLICK]);
			interaction.click.add(climbToBlimp);

			if( PerformanceUtils.qualityLevel >= PerformanceUtils.QUALITY_LOW )
			{
				setupClouds();
			}
			setupGoat();
			setupGrasshopper();
			setupLockedGate();
					
			super.addSystem( new ThresholdSystem(), SystemPriorities.update );
			super.shellApi.eventTriggered.add( eventTriggers );
			
			if( super.shellApi.checkEvent( _events.TELEPORT ))
			{
				if(PerformanceUtils.qualityLevel >= PerformanceUtils.QUALITY_MEDIUM)
				{
					var transportGroup:TransportGroup = super.addChildGroup( new TransportGroup()) as TransportGroup;
				}
				if(transportGroup)
				{
					transportGroup.transportIn( player );
				}
				else
				{
					this.shellApi.removeEvent(_events.TELEPORT);
					this.shellApi.triggerEvent(_events.TELEPORT_FINISHED);
				}
				if( super.shellApi.checkEvent( _events.TELEPORT_HERC ))
				{
					if(transportGroup) transportGroup.transportIn( super.getEntityById( "herc" ), false);
					super.shellApi.removeEvent( _events.TELEPORT_HERC );
				}
			}
			var minibillboard:AdMiniBillboard = new AdMiniBillboard(this,super.shellApi, new Point(180,802),"minibillboard/minibillboardSmallLegs.swf");	

			removeIslandParts();
		}
		
		private function climbToBlimp(ent:Entity):void
		{
			var rope:MovieClip = super.hitContainer["climb1"];
			var top:Number = rope.y - rope.height / 2;
			CharUtils.followPath(player, new <Point>[new Point(rope.x, top)], playerReachedTopBlimp, false, false, new Point(40, 40));
		}		
		
		private function playerReachedTopBlimp(...args):void
		{
			// if blimp takeover not active, then load map
			if (super.getGroupById(AdBlimpGroup.GROUP_ID) == null)
				getEntityById("exitToMap").get(SceneInteraction).activated = true;
		}
		
		private function removeIslandParts():void
		{
			
			var specialAbility:SpecialAbilityControl = player.get( SpecialAbilityControl );
			var specialAbilityData:SpecialAbilityData;
			var lookAspectData:LookAspectData;
			var lookData:LookData;
			
			if( specialAbility ) 
			{
				for each( specialAbilityData in specialAbility.specials )
				{
					if( specialAbilityData.id == "Grow" && !shellApi.checkEvent( GameEvent.GOT_ITEM + _events.HADES_CROWN ))
					{
						lookAspectData = SkinUtils.getLookAspect( player, SkinUtils.HAIR );
						lookData = new LookData();
						lookData.applyAspect( lookAspectData );
						
						specialAbility.removeSpecialByClass( Grow );
						SkinUtils.setSkinPart( player, SkinUtils.HAIR, "hades2" );
					}
					
					else if( specialAbilityData.id == "Electrify" && !shellApi.checkEvent( GameEvent.GOT_ITEM + _events.POSEIDON_TRIDENT ))
					{
						lookAspectData = SkinUtils.getLookAspect( player, SkinUtils.ITEM );
						lookData = new LookData();
						lookData.applyAspect( lookAspectData );
						
						specialAbility.removeSpecialByClass( Electrify );
						SkinUtils.removeLook( player, lookData );
					}
				}
				
				super.shellApi.saveLook();	
			}	
		}
		
		// process incoming events
		private function eventTriggers(event:String, save:Boolean = true, init:Boolean = false, removeEvent:String = null):void
		{
			if( event == _events.ZEUS_GATE_OPEN && !super.shellApi.checkEvent( _events.HERCULES_LOST ))
			{
				breakLock();
			}
			
			if( event == _events.TELEPORT_FINISHED )
			{
				if( super.shellApi.checkEvent( _events.HERCULES_CHILLING ))
				{
					if( !shellApi.checkEvent( _events.ZEUS_GATE_OPEN ))
					{
						SceneUtil.lockInput( this );
						
						var dialog:Dialog = player.get( Dialog );
						dialog.say( "unlock_gate" );
					}
				}
				super.shellApi.removeEvent( _events.TELEPORT_FINISHED );
			}
		}
		
		private function setupClouds():void
		{
			var points:Vector.<Point> = new Vector.<Point>;
			points.push( new Point( 2900, 1025 ), new Point( 2965, 985 ), new Point( 3040, 975 ), new Point( 3110, 1000 ), new Point( 3104, 1030 ), new Point( 3015, 1060 ));
			points.push( new Point( 2700, 844 ), new Point( 2775, 806 ), new Point( 2846, 795 ), new Point( 2930, 835 ), new Point( 2900, 850 ), new Point( 2820, 860 ));
			points.push( new Point( 3100, 865 ), new Point( 3160, 830 ), new Point( 3230, 815 ), new Point( 3315, 840 ), new Point( 3300, 870 ), new Point( 3200, 880 ));
			points.push( new Point( 3365, 860 ), new Point( 3425, 820 ), new Point( 3500, 800 ), new Point( 3580, 840 ), new Point( 3560, 860 ), new Point( 3475, 870 ));
			
			var cloud:Entity = getEntityById( "clouds" );	
			var display:Display = cloud.get( Display );
			
			var clip:MovieClip = display.displayObject[ "poof" ] as MovieClip;
			var wrapper:BitmapWrapper = this.convertToBitmapSprite( clip[ "content" ] );
			var sprite:Sprite;
			var bitmapData:BitmapData;
			var bitmap:Bitmap;
			var displayObjectBounds:Rectangle = clip.getBounds( clip );
			var offsetMatrix : Matrix = new Matrix( 1, 0, 0, 1, displayObjectBounds.left, displayObjectBounds.top );
			var clouds:int = 24;
			

			for( var number:int = 0; number < clouds; number ++ )
			{
				sprite = new Sprite();
				
				bitmapData = new BitmapData( clip.width, clip.height, true, 0x000000 );
				bitmapData.draw( wrapper.data, null );
				
				bitmap = new Bitmap( bitmapData, "auto", true );
				bitmap.transform.matrix = offsetMatrix;
				sprite.addChild( bitmap );
				sprite.mouseChildren = false;
				sprite.mouseEnabled = false;
				
				var poof:Entity = EntityUtils.createMovingEntity( this, sprite, display.displayObject );		
				var startX:Number = points[ number ].x - ( .5 * sprite.width );
				var startY:Number = points[ number ].y;// + ( .5 * sprite.height );
				EntityUtils.position( poof, startX, startY );
				
				Display( poof.get( Display )).alpha = .6;
				
				var motion:Motion = poof.get( Motion );
				motion.rotationFriction = 0;
				motion.rotationVelocity = ( Math.random() * 60 ) - 30;					
			}
			
			wrapper.sprite.visible = false;
			wrapper.bitmap.visible = false;
		}
		
		/*******************************
		 * 
		 * 			GRASSHOPPER	
		 * 
		 *******************************/
		
		private function setupGrasshopper():void
		{		
			var frog:MovieClip = super._hitContainer["frog"] as MovieClip;
			_hitContainer.setChildIndex(_hitContainer["frog"], _hitContainer.numChildren-1);	
			grassHopper = EntityUtils.createSpatialEntity(this,super._hitContainer["frog"]);
			grassHopper = TimelineUtils.convertClip( frog, this, grassHopper );
			Timeline(grassHopper.get(Timeline)).gotoAndStop("standRight");
			grassHopper.add(new Tween());	
			SceneUtil.addTimedEvent(this,new TimedEvent(Math.random() * 3,1,hop,true));
		}
		
		private function hop():void
		{
			// todo: add upward arcing jump
			var dir:int = Math.random() * 2;
			var dist:int = 0;
			var tween:Tween;
			var spatial:Spatial;
			var up:Number = EntityUtils.getPosition( grassHopper ).y;
			
			if(dir <= 0)
			{
				Timeline(grassHopper.get(Timeline)).gotoAndStop("hopLeft");
				dist = -100;
			}
			else
			{ 
				Timeline(grassHopper.get(Timeline)).gotoAndStop("hopRight");
				dist = 100;
			}
			tween = grassHopper.get( Tween );
			spatial = grassHopper.get( Spatial );
			tween.to(grassHopper.get(Spatial),0.5,{x:EntityUtils.getPosition(grassHopper).x + dist, ease:None.easeNone, onComplete:Command.create(land, dist) },"hopper");
			tween.to( spatial, 0.25, { y : up - 30, ease:None.easeNone, onComplete : startDescend });
		}
		
		private function startDescend():void
		{
			var tween:Tween = grassHopper.get( Tween );
			var spatial:Spatial = grassHopper.get( Spatial );
			var down:Number = EntityUtils.getPosition( grassHopper ).y;
			
			tween.to( spatial, 0.25, { y : down + 30, ease:None.easeNone });
		}
		
		private function land(dir:Number):void
		{
			if(dir < 0)
				Timeline(grassHopper.get(Timeline)).gotoAndStop("standLeft");
			else 
				Timeline(grassHopper.get(Timeline)).gotoAndStop("standRight");	
			Timeline(grassHopper.get(Timeline)).gotoAndStop("stand");
			SceneUtil.addTimedEvent(this,new TimedEvent(Math.random() * 3,1,hop,true));
		}		
		
		/*******************************
		 * 
		 * 			  GOAT	
		 * 
		 *******************************/
		
		private function setupGoat():void
		{
			// intermitent blinking
			var goat:MovieClip = super._hitContainer["goat1"]["avatar"]["head"]["eyes"] as MovieClip;
			var goatEnt:Entity = TimelineUtils.convertClip( goat, this );
			var timeline:Timeline = goatEnt.get( Timeline );
			
			SceneUtil.addTimedEvent(this, new TimedEvent(4, 0, Command.create( timeline.gotoAndPlay, "close" ), true),"goatblink");
		}
		
		/*******************************
		 * 
		 * 			   LOCK	
		 * 
		 *******************************/
		
		private function breakLock():void
		{
			var entity:Entity = super.getEntityById( "herc" );
			CharUtils.setAnim( entity, Attack );
			
			var timeline:Timeline = entity.get( Timeline );
			timeline.labelReached.add( hercLabelHandler );
		}
		
		public function hercLabelHandler( label:String ):void
		{
			if( label == "trigger" )
			{
				shatterLock();
				
				var entity:Entity = super.getEntityById( "herc" );
				var timeline:Timeline = CharUtils.getTimeline( entity );
				timeline.labelReached.remove( hercLabelHandler );
			}
		}
		
		private function shatterLock():void
		{
			var number:int;
			var entity:Entity;
			var motion:Motion;
			var spatial:Spatial;
			var clip:DisplayObject = _hitContainer[ "lockPiece" ];
			var threshold:Threshold;
			
			var wrapper:BitmapWrapper = this.convertToBitmapSprite( clip );
			var sprite:Sprite;
			var bitmapData:BitmapData;
			var bitmap:Bitmap;
			var displayObjectBounds:Rectangle = clip.getBounds( clip );
			var offsetMatrix : Matrix = new Matrix( 1, 0, 0, 1, displayObjectBounds.left, displayObjectBounds.top );
			
			clip = _hitContainer[ "lock" ];
			if( PerformanceUtils.determineQualityLevel() < PerformanceUtils.QUALITY_LOW )
			{
				_pieces = 5;
			}
			
			for( number = 1; number < _pieces + 1; number ++ )
			{
				sprite = new Sprite();
				
				bitmapData = new BitmapData( displayObjectBounds.width, displayObjectBounds.height, true, 0x000000 );
				bitmapData.draw( wrapper.data, null );
				
				bitmap = new Bitmap( bitmapData, "auto", true );
				bitmap.transform.matrix = offsetMatrix;
				sprite.addChild( bitmap );
				sprite.mouseChildren = false;
				sprite.mouseEnabled = false;
				
				entity = EntityUtils.createSpatialEntity( this, sprite, _hitContainer );
				spatial = entity.get( Spatial );
				spatial.x = clip.x + Math.random() * 20 - 10;
				spatial.y = clip.y - 90 + Math.random() * 20;
				spatial.scaleX = spatial.scaleY = ( Math.random() * 50 + 75 ) / 100;
				spatial.rotation = Math.random() * 360;
				
				motion = new Motion();
				motion.velocity.x = -Math.random() * 40;
				motion.velocity.y = -Math.random() * 120 + 5;	
				motion.acceleration = new Point();
				motion.acceleration.y = 500;
				
				entity.add( motion );
				
				threshold = new Threshold( "y", ">" );
				threshold.threshold = 1110;
				threshold.entered.addOnce( removePiece );
				
				entity.add( threshold );
			}
			
			shellApi.triggerEvent( _events.HERC_BREAK_LOCK );
			_hitContainer.removeChild( clip );
		}
		
		private function removePiece( ):void
		{
			_count++;
			if( _count == _pieces )
			{
				SceneUtil.lockInput( this, false );
				
				var entity:Entity = getEntityById( "herc" );
				var dialog:Dialog = entity.get( Dialog );
				dialog.say( "after_you" );
			}
		}
		
		private function setupLockedGate():void
		{
			var entity:Entity;
			
			if( shellApi.checkEvent( _events.ZEUS_GATE_OPEN ))
			{
				_hitContainer.removeChild( _hitContainer[ "lock" ]);
			}
			
			else
			{
				entity = getEntityById( "doorMountOlympus1" );
				SceneInteraction( entity.get( SceneInteraction )).reached.removeAll();
				SceneInteraction( entity.get( SceneInteraction )).reached.add( doorReached );	
			}
		}
		
		private function doorReached( char:Entity, door:Entity ):void
		{
			// lock controls
			SceneUtil.lockInput( this );
			if( shellApi.checkEvent( _events.ZEUS_GATE_OPEN ))
			{
				// open
				Door( door.get( Door )).open = true;
			}
			else
			{
				// not open
				Dialog( char.get( Dialog )).sayById( "gate_locked" );
				Dialog( char.get( Dialog )).complete.add( unlockInput );
			}
		}
		
		private function unlockInput( dialogData:DialogData = null ):void
		{
			SceneUtil.lockInput( this, false );
		}
		
		private var _count:int = 0;
		private var _pieces:int = 11;
		private var grassHopper:Entity;
		private var _events:MythEvents;
	}
}