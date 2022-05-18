package game.scenes.shrink.silvaOfficeShrunk01
{
	import com.greensock.easing.Linear;
	import com.greensock.easing.Quad;
	
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	
	import ash.core.Entity;
	
	import engine.components.AudioRange;
	import engine.components.Display;
	import engine.components.Id;
	import engine.components.Motion;
	import engine.components.Spatial;
	import engine.components.Tween;
	import engine.creators.InteractionCreator;
	import engine.managers.SoundManager;
	import engine.util.Command;
	
	import game.components.Emitter;
	import game.components.entity.Dialog;
	import game.components.entity.Sleep;
	import game.components.entity.collider.PlatformCollider;
	import game.components.entity.collider.RectangularCollider;
	import game.components.entity.collider.SceneObjectCollider;
	import game.components.entity.collider.WallCollider;
	import game.components.hit.Platform;
	import game.components.motion.FollowTarget;
	import game.components.motion.Mass;
	import game.components.scene.SceneInteraction;
	import game.creators.entity.EmitterCreator;
	import game.creators.motion.SceneObjectCreator;
	import game.creators.ui.ToolTipCreator;
	import game.data.TimedEvent;
	import game.data.animation.entity.character.Cry;
	import game.data.animation.entity.character.PushHigh;
	import game.data.display.BitmapWrapper;
	import game.scene.template.AudioGroup;
	import game.scene.template.PlatformerGameScene;
	import game.scenes.shrink.ShrinkEvents;
	import game.scenes.shrink.schoolCafetorium.SchoolCafetorium;
	import game.scenes.shrink.shared.particles.LaserCharge;
	import game.scenes.shrink.shared.popups.LooseScreen;
	import game.scenes.shrink.silvaOfficeShrunk01.ShrinkSystem.Shrink;
	import game.scenes.shrink.silvaOfficeShrunk01.ShrinkSystem.ShrinkSystem;
	import game.scenes.shrink.silvaOfficeShrunk01.SilvaSystem.Silva;
	import game.scenes.shrink.silvaOfficeShrunk01.SilvaSystem.SilvaSystem;
	import game.systems.SystemPriorities;
	import game.systems.hit.SceneObjectHitRectSystem;
	import game.systems.motion.SceneObjectMotionSystem;
	import game.util.AudioUtils;
	import game.util.BitmapUtils;
	import game.util.CharUtils;
	import game.util.DisplayUtils;
	import game.util.EntityUtils;
	import game.util.PlatformUtils;
	import game.util.SceneUtil;
	import game.util.TweenUtils;
	
	public class SilvaOfficeShrunk01 extends PlatformerGameScene
	{
		public function SilvaOfficeShrunk01()
		{
			super();
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{			
			super.groupPrefix = "scenes/shrink/silvaOfficeShrunk01/";
			
			super.init(container);
		}
		
		// initiate asset load of scene specific assets.
		override public function load():void
		{
			super.load();
		}
		
		private var globeShrunk:Boolean = false;
		private var globe:Entity;
		private var mirror:Entity;
		private var mrsilva:Entity;
		private var cj:Entity;
		private const SHRINKABLE:String = "shrinkable";
		private const MIRRORNUMBER:int = 18;
		private const GLOBENUMBER:int = 13;
		private var shrink:ShrinkEvents;
		private var charge:LaserCharge;
		private var emitter:Emitter;
		private var _sceneObjectCreator:SceneObjectCreator;
		
		// all assets ready
		override public function loaded():void
		{
			super.loaded();
			
			shrink = events as ShrinkEvents;
			cj = getEntityById("cj");
			Display(cj.get(Display)).visible = false;
			ToolTipCreator.removeFromEntity( cj );
		//	ToolTipCreator.addToEntity(cj, ToolTipType.NAVIGATION_ARROW);
			
			player.add(new SceneObjectCollider());
			player.add(new RectangularCollider());
			player.add(new Mass(100));
			
			setUpHidingObjects();
			setUpSilva();
			hideTargets();
			
			addSystem( new SceneObjectHitRectSystem());
			addSystem( new ShrinkSystem());
			addSystem( new SceneObjectMotionSystem(), SystemPriorities.moveComplete );
		}
		
		private function hideTargets():void
		{
			var targets:Array = [ "cj", "silva" ];
			for( var i:int = 0; i < targets.length; i++ )
			{
				var clip:MovieClip = _hitContainer[ targets[ i ] + "Target" ];
				clip.alpha = 0;
			}
		}
		
		private function setUpHidingObjects():void
		{
			var range:AudioRange = new AudioRange(500,0,5,Quad.easeIn);
			var clip:MovieClip;
			var display:Display;
			var hitClip:MovieClip;
			var wrapper:BitmapWrapper;
			var shrink:Shrink;
			var shrinkHit:Entity;
			var shrinkableEntity:Entity;
			var audioGroup:AudioGroup = getGroupById( AudioGroup.GROUP_ID ) as AudioGroup;
			
			// BITMAP THE DISPLAY DO SOMETHING WITH THE HITS
			for(var i:int = 1; i <= MIRRORNUMBER; i++)
			{
				if(i == GLOBENUMBER)
				{
					setUpGlobe( display, audioGroup );
				}
				
				else
				{
					clip = _hitContainer[ SHRINKABLE + i ];
					hitClip = _hitContainer[ "shrinkHit" + i ];
					if( hitClip == null )
					{
						hitClip = clip;
					}
					
					wrapper = DisplayUtils.convertToBitmapSprite( hitClip );
					shrinkHit = EntityUtils.createSpatialEntity( this, wrapper.sprite, _hitContainer );
					display = shrinkHit.get( Display );
					display.alpha = 0;
					shrink = new Shrink( display.displayObject, .25, 2, 3 );
					
					wrapper = DisplayUtils.convertToBitmapSprite( clip );
					shrinkableEntity = EntityUtils.createSpatialEntity(this, wrapper.sprite, _hitContainer);
					
					shrinkableEntity.add( new Id( clip.name )).add( shrink ).add( range ).add( new Tween()); //.add( new Audio())
					audioGroup.addAudioToEntity( shrinkableEntity );
					Display( shrinkableEntity.get( Display )).moveToFront();
				}
			}
			
			mirror = getEntityById( SHRINKABLE + MIRRORNUMBER );
			Shrink( mirror.get( Shrink )).shrinkable = false;
		}
		
		private function setUpGlobe( display:Display, audioGroup:AudioGroup ):void
		{
			_sceneObjectCreator = new SceneObjectCreator();
			
			var motion:Motion = new Motion();
			motion.friction = new Point( 100, 100 );
			motion.pause = true;
			
			var clip:MovieClip = _hitContainer[ SHRINKABLE + GLOBENUMBER ];
			var wrapper:BitmapWrapper = DisplayUtils.convertToBitmapSprite( clip );
			var globeEdge:Rectangle = wrapper.sprite.getRect( wrapper.sprite );
			
			var shrink:Shrink = new Shrink( display.displayObject, .5, 2, 1 );
			
			globe = _sceneObjectCreator.createCircle( wrapper.sprite, .9, _hitContainer, NaN, NaN,motion, null, sceneData.bounds, this, null, null, 200, true );
			globe.add( new WallCollider()).add( new PlatformCollider()).add( new Id( clip.name )).add( shrink ).add( new Tween());
			audioGroup.addAudioToEntity( globe );
			
			clip = _hitContainer[ "globeHit" ];
			wrapper = DisplayUtils.convertToBitmapSprite( clip );
			
			var follow:FollowTarget = new FollowTarget( globe.get( Spatial ));
			follow.offset = new Point( 0, globeEdge.top * .5 );
			
			var collider:Entity = EntityUtils.createSpatialEntity( this, wrapper.sprite, _hitContainer );
			collider.add( new Platform()).add( follow );
			display = collider.get( Display );
			display.alpha = 0;
		}
		
		private function setUpSilva():void
		{
			addSystem(new SilvaSystem());
			
			mrsilva = getEntityById("mrSilva");
			mrsilva.remove(Sleep);
			
			Spatial( mrsilva.get( Spatial )).y -= 500;
			
			var clip:MovieClip = _hitContainer["gun"];
			if( !PlatformUtils.isDesktop )
			{
				BitmapUtils.convertContainer(clip);
			}
			
			var gun:Entity = EntityUtils.createSpatialEntity(this, clip, _hitContainer);
			
			charge = new LaserCharge();
			charge.init(0x00e69a, 0x009999);
			var laserCharge:Entity = EmitterCreator.create(this,clip,charge,0,0,gun,"chargeEmitter");
			emitter = laserCharge.get(Emitter);
			
			gun.add(new Silva(mrsilva.get(Spatial), emitter, this, clip, new Point(-75, -150), new Point(-500, - 750)))
				.add(new FollowTarget(player.get(Spatial),.1)).add(new Id("gun"));
			FollowTarget(gun.get(FollowTarget)).offset = new Point(-500, -750);
			
			Display(gun.get(Display)).moveToFront();
			Silva(gun.get(Silva)).shoot.add(silvaFired);
			
			clip = _hitContainer[ "switchTarget" ];
			var wrapper:BitmapWrapper = DisplayUtils.convertToBitmapSprite( clip );
			var interact:Entity = EntityUtils.createSpatialEntity( this, wrapper.sprite, _hitContainer );
			interact.add( new Id( "switchTarget" ));
			Display( interact.get( Display )).alpha = 0;
		}
		
		private function silvaFired( point:Point ):void
		{
			var gun:Entity;
			var silva:Silva;
			var shrink:Shrink;
			var shotPlayer:Boolean = true;
			for( var i:int = 1; i <= MIRRORNUMBER; i++ )
			{
				shrink = getEntityById( SHRINKABLE + i ).get( Shrink );
				if( shrink.isTarget(point, _hitContainer ))
				{
					if( !shrink.isShrunk )
					{
						if( i != MIRRORNUMBER )
						{
							shrink.shrink = true;
						
							if(i == GLOBENUMBER - 1)
							{
								var motion:Motion = globe.get(Motion);
								motion.pause = false;
								shrink = getEntityById( SHRINKABLE + GLOBENUMBER ).get( Shrink );
								shrink.shrink = true;
								CharUtils.moveToTarget(player, motion.x - 200, Spatial(player.get(Spatial)).y,true, returnControls)
							}
						}
						else
						{
							gun = getEntityById("gun");
							silva = gun.get(Silva);
							gun.remove( FollowTarget );
							gun.add( new FollowTarget( new Spatial( 3000, 540 ), .1 ));
							
							silva.backFire = true;
							SceneUtil.lockInput(this);
							SceneUtil.addTimedEvent(this ,new TimedEvent( silva.shootTime, 1, shrinkSilva ));
						}
						
						shotPlayer = false;
						break;
					}
				}
			}
			
			if( shotPlayer )
			{
				playerWasShot();
			}
		}
		
		//win sequence
		private function shrinkSilva():void
		{
			trace("shrink silva and you win");
			
			shellApi.triggerEvent( shrink.SHRUNK_SILVA, true );
			removeSystemByClass( SilvaSystem );
			var gun:Entity = getEntityById( "gun" );
			gun.remove( FollowTarget );
			gun.remove( Silva );
			removeEntity( getEntityById( "laser" ));
			TweenUtils.entityTo( gun, Spatial, 1, { x : 2625, y : 1250, rotation : 185, ease : Linear.easeIn, onComplete : setUpGun });
		}
		
		private function setUpGun():void
		{
			var gun:Entity = getEntityById( "gun" );
			var clip:MovieClip = Display( gun.get( Display )).displayObject.hand as MovieClip;
			Display( gun.get( Display )).moveToBack();
			
			for( var i:int = 1; i <= 2; i++ )
			{
				var hide:Entity = getEntityById( SHRINKABLE + i );
				Display( hide.get( Display )).moveToBack();
			}
			
			var hand:Entity = EntityUtils.createSpatialEntity(this, clip);
			
			var interact:Entity = getEntityById( "switchTarget" );
			
			InteractionCreator.addToEntity( interact, ["click"]);
			var interaction:SceneInteraction = new SceneInteraction();
			interaction.minTargetDelta = new Point(25, 100);
			interaction.reached.add( Command.create( flipSwitch, hand ));
			ToolTipCreator.addToEntity(interact);
			interact.add(interaction);
			
			TweenUtils.entityTo(mrsilva, Spatial, .5,{y:450, ease:Linear.easeIn, onComplete:silvaCries});
			SceneUtil.setCameraTarget(this, mrsilva);
			
			charge.setColor(0x0066FF, 0x0066FF);
			
			enterCJ();
		}
		
		private function enterCJ():void
		{
			Display(cj.get(Display)).visible = true;
			ToolTipCreator.addToEntity(cj);
		}
		
		private function silvaCries():void
		{
			CharUtils.setAnim( mrsilva, Cry );
			SceneUtil.addTimedEvent( this, new TimedEvent( 1, 1, confrontSilva ));
		}
		
		private function confrontSilva():void
		{
			var target:MovieClip = _hitContainer[ "silvaTarget" ];
			SceneUtil.setCameraTarget( this, player );
			CharUtils.moveToTarget( player, target.x, target.y, false, takeThat );
		}
		
		private function takeThat( ...args ):void
		{
			var dialog:Dialog = player.get( Dialog );
			
			dialog.sayById( "karma" );
			
			dialog = mrsilva.get( Dialog );
			dialog.complete.addOnce( goSeeCJ );
		}
		
		private function goSeeCJ( ...args ):void
		{
			var target:MovieClip = _hitContainer[ "cjTarget" ];
			SceneUtil.setCameraTarget( this, player );
			
			var path:Vector.<Point> = new Vector.<Point>();
			path.push( new Point( 1700, 625 ), new Point( 1725, 825 ), new Point( cj.get( Spatial ).x - 100, cj.get( Spatial ).y ));
			CharUtils.followPath( player, path, talkToCJ, false );
		}
		
		private function talkToCJ( ...args ):void
		{
			var dialog:Dialog = cj.get( Dialog );

			dialog.setCurrentById( "gj" );
			dialog.sayById( "gj" );
			dialog.complete.addOnce( returnControls );
		}
		
		private function returnControls( ...args ):void
		{
			SceneUtil.lockInput(this, false);
		}
		
		private function flipSwitch( player:Entity, target:Entity, hand:Entity ):void
		{
			SceneUtil.lockInput(this);
			CharUtils.setAnim( player, PushHigh );
			TweenUtils.entityTo( hand, Spatial, 1, { rotation : 15, ease : Linear.easeIn, onComplete : getReadyToGrow });
		}
		
		private function getReadyToGrow():void
		{
			emitter.start = true;
			emitter.emitter.counter.resume();
			
			var target:MovieClip = _hitContainer[ "cjTarget" ];
			CharUtils.moveToTarget( player, target.x + 50, target.y, false, fadeToBlue );
		}
		
		private function fadeToBlue( ...args ):void
		{
			var clip:MovieClip = new MovieClip();
			clip.graphics.beginFill( 0x0066FF );
			clip.graphics.drawRect( 0, 0, shellApi.camera.viewportWidth, shellApi.camera.viewportHeight );
			clip.graphics.endFill();
			var fade:Entity = EntityUtils.createSpatialEntity( this, clip, this.overlayContainer );
			Display( fade.get( Display )).alpha = 0;
			TweenUtils.entityTo( fade, Display, 3,{ alpha:1, ease:Linear.easeNone, onComplete:goToScienceFair });
		}
		
		private function goToScienceFair():void
		{
			shellApi.loadScene(SchoolCafetorium,2250);
		}
		
		// lose sequence
		private function playerWasShot():void
		{
			SceneUtil.lockInput( this );
			SceneUtil.addTimedEvent( this, new TimedEvent( .01, 100, shrinkPlayer ));
			AudioUtils.play( this, SoundManager.EFFECTS_PATH + "shrink_01.mp3" );
		}
		
		private function shrinkPlayer():void
		{
			CharUtils.setScale( player, Spatial( player.get( Spatial )).scale - .0025 );
			if( Spatial( player.get( Spatial )).scale < .11 )
				playerGetsShrunk();
		}
		
		private function playerGetsShrunk():void
		{
			SceneUtil.lockInput( this, false );
			addChildGroup( new LooseScreen( overlayContainer ));
		}
	}
}