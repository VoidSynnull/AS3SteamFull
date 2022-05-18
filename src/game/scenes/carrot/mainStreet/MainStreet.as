package game.scenes.carrot.mainStreet
{
	import com.greensock.easing.Sine;
	
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.geom.Point;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Interaction;
	import engine.components.Motion;
	import engine.components.Spatial;
	import engine.components.SpatialAddition;
	import engine.components.Tween;
	import engine.creators.InteractionCreator;
	import engine.util.Command;
	
	import game.components.entity.Dialog;
	import game.components.entity.OriginPoint;
	import game.components.entity.character.animation.RigAnimation;
	import game.components.motion.Threshold;
	import game.components.motion.WaveMotion;
	import game.components.scene.SceneInteraction;
	import game.creators.ui.ToolTipCreator;
	import game.data.TimedEvent;
	import game.data.WaveMotionData;
	import game.data.animation.Animation;
	import game.data.animation.entity.character.Proud;
	import game.data.character.LookAspectData;
	import game.data.character.LookData;
	import game.data.comm.PopResponse;
	import game.data.game.GameEvent;
	import game.data.ui.ToolTipType;
	import game.scene.template.CharacterGroup;
	import game.scene.template.ItemGroup;
	import game.scene.template.PlatformerGameScene;
	import game.scene.template.ads.AdBlimpGroup;
	import game.scenes.carrot.CarrotEvents;
	import game.scenes.custom.AdMiniBillboard;
	import game.systems.motion.ThresholdSystem;
	import game.systems.motion.WaveMotionSystem;
	import game.ui.popup.IslandEndingPopup;
	import game.util.CharUtils;
	import game.util.EntityUtils;
	import game.util.SceneUtil;
	import game.util.SkinUtils;
	
	public class MainStreet extends PlatformerGameScene
	{
		public function MainStreet()
		{
			super();
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{			
			super.groupPrefix = "scenes/carrot/mainStreet/";
			super.init(container);
		}
		
		// initiate asset load of scene specific assets.
		override public function load():void
		{
			super.load();
			// loading any additional assets in here...
		}
		
		// all assets ready
		override public function loaded():void
		{
			_events = super.events as CarrotEvents;
			
			super.addSystem( new ThresholdSystem() );
			super.addSystem( new WaveMotionSystem() );
			
			// tool tip on rope
			var rope:Entity = EntityUtils.createSpatialEntity(super, super.hitContainer["climb1"]);
			rope.get(Display).alpha = 0;
			// if not mobile then add tool tip text on basket (blank if blimp takeover)
			var toolTipText:String = (super.getGroupById(AdBlimpGroup.GROUP_ID) == null) ? "TRAVEL" : "";			
			ToolTipCreator.addToEntity(rope,ToolTipType.EXIT_UP, toolTipText);
			// rope behavior
			var interaction:Interaction = InteractionCreator.addToEntity(rope, [InteractionCreator.CLICK]);
			interaction.click.add(climbToBlimp);

			if( shellApi.checkEvent( _events.CAT_FOLLOWING ))
			{
				var cat:Entity = super.getEntityById("cat");
				ToolTipCreator.removeFromEntity(cat);
				cat.get(Spatial).x = shellApi.player.get(Spatial).x;
				cat.get(Spatial).y = shellApi.player.get(Spatial).y;
				var charGroup:CharacterGroup = super.getGroupById("characterGroup") as CharacterGroup;
				charGroup.addFSM( cat );
				CharUtils.followEntity( cat, shellApi.player, new Point(300, 200) );
			}
			
			if ( shellApi.checkEvent( _events.DESTROYED_RABBOT ))
			{
				setupButterflies();
				// if player has not received medal, trigger medal awarding sequence
				if( !super.shellApi.checkEvent( GameEvent.GOT_ITEM + _events.MEDAL_CARROT ))
				{
					awardMedalSequence();
				}
			}
			else
			{
				hideButterflies();
				MovieClip( super._hitContainer[ "hole" ] ).visible = false;
			}
			
			if( !shellApi.checkEvent( GameEvent.GOT_ITEM + _events.DRONE_EARS ))
			{
				var lookAspectData:LookAspectData = SkinUtils.getLookAspect( player, SkinUtils.FACIAL );
				if (lookAspectData) {
					var lookData:LookData = new LookData();
					lookData.applyAspect( lookAspectData );
					
					if( lookAspectData.value == "rabbitcon2" )
					{
						SkinUtils.removeLook( player, lookData );
					}
				}
			}

			setupLeaves();
			var minibillboard:AdMiniBillboard = new AdMiniBillboard(this,super.shellApi, new Point(1368,395));			
			super.loaded();
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
		
		private function awardMedalSequence():void
		{
			// position player directly next to mayor
			var spatial:Spatial = super.player.get(Spatial);
			spatial.x = 850;
			spatial.y = 940;
			CharUtils.setDirection( super.player, false );
			
			SceneUtil.lockInput(this, true, false);
			super.shellApi.eventTriggered.add( onEventTriggered );
			Dialog( super.getEntityById( "char1" ).get(Dialog)).sayById("destroyed_rabbot");
		}

		// NOTE :: Should we be listening to this in scene, does it need to be processed first?
		private function onEventTriggered( event:String, makeCurrent:Boolean = true, init:Boolean = false, removeEvent:String = null ):void
		{
			if( event == _events.AWARD_MEDAL )
			{
				super.shellApi.eventTriggered.remove( onEventTriggered );
				super.shellApi.getItem( _events.MEDAL_CARROT );
				ItemGroup(super.getGroupById( ItemGroup.GROUP_ID )).showItem( _events.MEDAL_CARROT, "", null, onMedalReceived );
				super.shellApi.triggerEvent( _events.VICTORY, true );
				//shellApi.completedIsland();
			}
		}
		
		private function onMedalReceived():void
		{
			CharUtils.setAnim(super.player, Proud);
			RigAnimation( CharUtils.getRigAnim( super.player) ).ended.add( onCelebrateEnd );
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

		private function setupButterflies():void 
		{
			var butterfly:Entity;
			var spatial:Spatial;
			var tween:Tween = new Tween();
			
			for ( var i:int = 0; i < 2; i ++ )
			{
				butterfly = EntityUtils.createMovingEntity( this, super._hitContainer[ "butterfly" + ( i + 1 )]);
				spatial = butterfly.get( Spatial );
				butterfly.add( tween ).add( new OriginPoint(spatial.x, spatial.y)).add( new SpatialAddition() );
				
				moveButterfly( butterfly );
			}
		}
		
		private function hideButterflies( ):void 
		{
			var butterfly:Entity;
			var display:Display;
			for ( var i:int = 0; i < 2; i ++ )
			{
				butterfly = EntityUtils.createSpatialEntity( this, super._hitContainer[ "butterfly" + ( i + 1 )]);
				display = butterfly.get( Display );
				display.visible = false;
			}
		}
		
		private function moveButterfly( butterfly:Entity ):void 
		{
			var spatial:Spatial = butterfly.get( Spatial );
			var motion:Motion = butterfly.get( Motion );
			var origin:OriginPoint = butterfly.get( OriginPoint );
			var wave:WaveMotion = new WaveMotion();
			wave.add( new WaveMotionData( "x", Math.random() * 10, Math.random() / 10 ));
			wave.add( new WaveMotionData( "y", Math.random() * 10, Math.random() / 10 ));
			
			var goalX:Number;
			var goalY:Number;
			var duration:Number; 
			
			goalX = ( Math.random() * 200 ) + origin.x - 100;
			goalY = ( Math.random() * 200 ) + origin.y - 100;
			
			duration = ( Math.random() * 3 ) + 8;
			
			butterfly.add( wave );
			var tween:Tween = butterfly.get( Tween );
			
			tween.to( spatial, duration, { x: goalX,     
				y: goalY, 
				ease:Sine.easeInOut,
				onComplete: moveButterfly,
				onCompleteParams:[ butterfly ]}); 	
		}
		
		private function setupLeaves():void
		{
			var leaf:Entity;
			var spatial:Spatial;
			var rotation:Number;
			_leaves = new Vector.<Entity>;
			var motion:Motion;
			
			for ( var i:int = 0; i < 2; i ++ )
			{
				leaf = EntityUtils.createMovingEntity( this, super._hitContainer[ "leaf" + ( i + 1 )]);
				spatial = leaf.get( Spatial );
				rotation = spatial.rotation;
				
				leaf.add( new OriginPoint(spatial.x, spatial.y, rotation) );
				_leaves.push( leaf );
			}
			
			dropLeaf();
		}
		
		private function dropLeaf( ):void 
		{
			var number:int = Math.round( Math.random() );
			var leaf:Entity = _leaves[ number ];
			var motion:Motion = leaf.get( Motion );
			var spatial:Spatial = leaf.get( Spatial );
			var spatialAddition:SpatialAddition = new SpatialAddition(); 
			
			motion.acceleration.y = 12;
			motion.maxVelocity = new Point( 5, 40 );
			
			var wave:WaveMotion = new WaveMotion();
			
			wave.add( new WaveMotionData( "x", 15, .05 ));
			wave.add( new WaveMotionData( "rotation", -30, .05 ));
			
			var threshold:Threshold = new Threshold( "y", ">" );
			threshold.threshold = 917;
			threshold.entered.addOnce( Command.create( leafWait, leaf ));
			leaf.add( threshold ).add( spatialAddition ).add( wave );
		}
		
		private function leafWait( leaf:Entity ):void
		{
			var motion:Motion = leaf.get( Motion );
			motion.velocity.y = 0;
			motion.acceleration.y = 0;
			motion.rotationAcceleration = 0;
			motion.rotationVelocity = 0;
			
			var tween:Tween = new Tween();
			var display:Display = leaf.get( Display ); 
			
			tween.to( display, 3, { alpha : 0 } );
			
			leaf.remove( WaveMotion );
			leaf.add( tween );
			SceneUtil.addTimedEvent( this, new TimedEvent( 3, 1, Command.create( resetLeaf, leaf )));
		}
		
		private function resetLeaf( leaf:Entity ):void
		{
			leaf.remove( SpatialAddition );
			var spatial:Spatial = leaf.get( Spatial );
			var origin:OriginPoint = leaf.get( OriginPoint );
			
			spatial.x = origin.x;
			spatial.y = origin.y;
			spatial.rotation = origin.rotation;
			
			var tween:Tween = leaf.get( Tween );
			var display:Display = leaf.get( Display ); 
			tween.to( display, 1, { alpha : 100 } );
			
			SceneUtil.addTimedEvent( this, new TimedEvent( 3, 1, dropLeaf ));
		}
		
		private var _events:CarrotEvents;
		private var _leaves:Vector.<Entity>
	}
}

