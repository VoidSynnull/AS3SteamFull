// Used by
// Card "gauntlets" on con3 island using item poptropicon_goldface_front

package game.data.specialAbility.islands.poptropicon
{
	import flash.display.BitmapData;
	import flash.display.MovieClip;
	import flash.geom.Point;
	
	import ash.core.Entity;
	import ash.core.NodeList;
	
	import engine.components.Audio;
	import engine.components.Display;
	import engine.components.Id;
	import engine.components.Motion;
	import engine.components.Spatial;
	import engine.components.Tween;
	import engine.managers.SoundManager;
	
	import fl.motion.easing.Quadratic;
	
	import game.components.Emitter;
	import game.components.entity.Dialog;
	import game.components.entity.character.Rig;
	import game.components.entity.character.part.PartLayer;
	import game.components.hit.EntityIdList;
	import game.components.motion.Destination;
	import game.components.timeline.Timeline;
	import game.components.ui.Button;
	import game.creators.entity.EmitterCreator;
	import game.data.animation.entity.character.Sword;
	import game.data.scene.characterDialog.DialogData;
	import game.data.specialAbility.SpecialAbility;
	import game.nodes.specialAbility.SpecialAbilityNode;
	import game.scenes.con3.shared.GauntletControllerNode;
	import game.scenes.con3.shared.GauntletResponder;
	import game.scenes.con3.shared.Gauntlets;
	import game.systems.entity.character.states.CharacterState;
	import game.util.AudioUtils;
	import game.util.BitmapUtils;
	import game.util.CharUtils;
	import game.util.DisplayUtils;
	import game.util.EntityUtils;
	import game.util.PerformanceUtils;
	import game.util.SceneUtil;
	import game.util.SkinUtils;
	
	import org.flintparticles.common.actions.Age;
	import org.flintparticles.common.actions.Fade;
	import org.flintparticles.common.actions.ScaleImage;
	import org.flintparticles.common.counters.Blast;
	import org.flintparticles.common.counters.Pulse;
	import org.flintparticles.common.counters.ZeroCounter;
	import org.flintparticles.common.displayObjects.Blob;
	import org.flintparticles.common.displayObjects.Ring;
	import org.flintparticles.common.initializers.BitmapImage;
	import org.flintparticles.common.initializers.ColorInit;
	import org.flintparticles.common.initializers.ImageClass;
	import org.flintparticles.common.initializers.Lifetime;
	import org.flintparticles.twoD.actions.Move;
	import org.flintparticles.twoD.actions.MutualGravity;
	import org.flintparticles.twoD.actions.RandomDrift;
	import org.flintparticles.twoD.emitters.Emitter2D;
	import org.flintparticles.twoD.initializers.Position;
	import org.flintparticles.twoD.initializers.Velocity;
	import org.flintparticles.twoD.zones.DiscZone;
	
	/**
	 * Power Glove for Poptropicon 3 island 
	 */
	public class PowerGlove extends SpecialAbility
	{
		private const TRIGGER:String	=	"trigger";
		
		private var _charged:Boolean;
		private var blast:String;
		private var _gauntlets:Gauntlets;
		
		private var _gloveFront:Entity;
		private var _gloveBack:Entity;
		
		/**
		 * SETUP GAUNTLETS AND THEIR MECHANICAL GLOW
		 */
		override public function init( node:SpecialAbilityNode ):void
		{
			super.init(node);
			
			_gauntlets = new Gauntlets();
			super.entity.add( _gauntlets );
			
			SkinUtils.setSkinPart( super.entity, SkinUtils.ITEM2, "poptropicon_goldface_back", true, setupRig );
		}
		
		private function setupRig( ...args ):void
		{
			var rig:Rig = super.entity.get( Rig );
			_gloveFront = rig.getPart( CharUtils.ITEM );
			_gloveBack = rig.getPart( SkinUtils.ITEM2 );
			
			var gauntletButton:Entity = super.group.getEntityById( "gauntletsButton" );
			var button:Button;
			if( gauntletButton )
			{
				button = gauntletButton.get( Button );
				button.isSelected = true;
			}
			
			_charged = super.shellApi.checkEvent( "weapons_powered_up" );
			setupPowered( new <Display>[ _gloveFront.get( Display ), _gloveBack.get( Display )]);
		}
		
		private function setupPowered( displays:Vector.<Display> ):void
		{
			var clip:MovieClip;
			
			for each( var display:Display in displays )
			{
				clip = display.displayObject;
				if( _charged )
				{
					// glow
					clip[ "normal" ].alpha = 0;
					clip[ "glow" ].alpha = 0;
				}
				else
				{
					clip[ "powered" ].alpha = 0;
					clip[ "powered_glow" ].alpha = 0;
//					clip.removeChild( clip[ "powered" ]);
//					clip.removeChild( clip[ "powered_glow" ]);
				}
			}
				
			addGlow( _gloveFront, "glow_front" );
			addGlow( _gloveBack, "glow_back" );
		}
		
		private function addGlow( glove:Entity, name:String ):void
		{
			var clip:MovieClip;
			var glow:Entity;
			var gloveDisplay:MovieClip = glove.get( Display ).displayObject as MovieClip;
			var partLayer:PartLayer;
			var armPart:String = name.indexOf( "front" ) > 0 ? CharUtils.ARM_FRONT : CharUtils.ARM_BACK;
			
			clip = _charged ? gloveDisplay[ "powered_glow" ] : gloveDisplay[ "glow" ];
			partLayer = glove.get( PartLayer );
			
			if( super.shellApi.checkEvent( "gauntlets_charged" ))
			{
				if( clip && PerformanceUtils.qualityLevel > PerformanceUtils.QUALITY_HIGH )
				{
					glow = EntityUtils.createSpatialEntity( super.entity.group, clip );
					glow.add( new Tween()).add( new Id( name ));
					
					growGlow( glow );
				}
				
				if( name.indexOf( "front" ) > 0 )
				{
					addEmitter( glove );
				}
			}
			else
			{
				clip.alpha = 0;
			}
			partLayer.setInsert( armPart );
		}
		
		private function addEmitter( glove:Entity ):void
		{
			var maxSize:Number;
			var velocity:Number;
			var time:Number;
			
			if( super.shellApi.checkEvent( "weapons_powered_up" ))
			{
				maxSize = 6;
				velocity = 2;
				time = 1;
				blast = "electrical_impact_01.mp3"
			}
			else
			{
				maxSize = 3;
				velocity = 1;
				time = .5;
				blast = "electric_zap_03.mp3"
			}
			
			var emitterEntity:Entity;
			var emitter2D:Emitter2D = new Emitter2D();
			var bitmapData:BitmapData;
			
			var display:Display = super.entity.get( Display );
			var gloveDisplay:Display = _gloveFront.get( Display );
			
			// BLAST EFFECT	
			bitmapData = BitmapUtils.createBitmapData( new Blob( 12 ));
			
			emitter2D = new Emitter2D();
			emitter2D.counter = new ZeroCounter();
			emitter2D.addInitializer( new BitmapImage( bitmapData, true, 20 * PerformanceUtils.defaultBitmapQuality ));
			emitter2D.addInitializer( new ColorInit( 0x0066FF, 0x70BEFF ));
			emitter2D.addInitializer( new Position( new DiscZone( new Point( 0, 0 ), 5, 5 )));
			emitter2D.addInitializer( new Lifetime( .5 ));
			
			emitter2D.addInitializer( new Velocity( new DiscZone( new Point( 0, 0 ), 100, 100 )));
			
			emitter2D.addAction( new MutualGravity( 1, 10, 1 ));
			emitter2D.addAction( new RandomDrift( velocity * 50, velocity * 50 ));
			emitter2D.addAction( new Fade( .75, 1 ));			
			emitter2D.addAction( new ScaleImage( 1, .5 ));	
			emitter2D.addAction( new Age());
			emitter2D.addAction( new Move());
			
			EmitterCreator.create( super.group, gloveDisplay.displayObject.sparks, emitter2D, 0, 0, null, "blastEmitter" );
			
			
			// RING EFFECT]
			emitter2D = new Emitter2D();
			emitter2D.counter = new ZeroCounter();
			
			emitter2D.addInitializer( new ImageClass( Ring, [ 11, 12 ], true, 5 )); 
			emitter2D.addInitializer( new ColorInit( 0x0066FF, 0x70BEFF ));
			emitter2D.addInitializer( new Position( new DiscZone( new Point( 0, 0 ), 0, 0 )));
			emitter2D.addInitializer( new Lifetime( time ));
			
			emitter2D.addAction( new Fade( .75, .5 ));			
			emitter2D.addAction( new ScaleImage( .1, maxSize ));	
			emitter2D.addAction( new Age());
			emitter2D.addAction( new Move());
			
			emitterEntity = EmitterCreator.create( super.group, display.container, emitter2D, 0, 0, null, "ringEmitter" );
		}
		
		/**
		 * GLOW TWEENS
		 */
		private function shrinkGlow( glow:Entity ):void
		{
			var tween:Tween = glow.get( Tween );
			var spatial:Spatial = glow.get( Spatial );
			
			tween.to( spatial, 2, { scale : 1, ease : Quadratic.easeIn, onComplete : growGlow, onCompleteParams : [ glow ]});
		}
		
		private function growGlow( glow:Entity ):void
		{
			var tween:Tween = glow.get( Tween );
			var spatial:Spatial = glow.get( Spatial );
			
			tween.to( spatial, 2, { scale : 2.5, ease : Quadratic.easeOut, onComplete : shrinkGlow, onCompleteParams : [ glow ]});
		}
		
		/**
		 * SPECIAL ABILITY TRIGGERED
		 */
		override public function activate( node:SpecialAbilityNode ):void
		{
			if( super.shellApi.checkEvent( "gauntlets_charged" ))
			{
				if( _gauntlets.responder )
				{
					var gauntletResponder:GauntletResponder = _gauntlets.responder.get( GauntletResponder );
					var motion:Motion = _gauntlets.responder.get( Motion );
					
					if( motion )
					{
						if( motion.velocity.y == 0 )
						{
							var spatial:Spatial = _gauntlets.controller.get( Spatial );
							var charSpatial:Spatial = node.entity.get( Spatial );
							
							// APPROACH THE PANEL
							var offsetX:Number = spatial.x < charSpatial.x ? gauntletResponder.offset.x : -gauntletResponder.offset.x;
							var offsetY:Number = gauntletResponder.offset.y;
							var destination:Destination = CharUtils.moveToTarget( node.entity, spatial.x + offsetX, spatial.y + offsetY, false, usePowerGloves );
							
							destination.validCharStates = new <String>[ CharacterState.STAND ];
						}
						
						else
						{
							_gauntlets.controller = null;
							_gauntlets.responder = null;
						}
					}
				}
				else
				{
					usePowerGloves();
				}
			}
			else
			{
				var dialog:Dialog = node.entity.get( Dialog );
				dialog.say( "nice_gloves" );
			}
		}
		
		// PLAYER IS POSITIONED
		private function usePowerGloves( character:Entity = null ):void
		{
			var charSpatial:Spatial = super.entity.get( Spatial );
			var spatial:Spatial;
			
			if( _gauntlets.controller )
			{
				spatial = _gauntlets.controller.get( Spatial );
				
				if( charSpatial.x < spatial.x )
				{
					CharUtils.setDirection( super.entity, true );
				}
				else
				{
					CharUtils.setDirection( super.entity, false );
				}
			}
			if( CharUtils.getStateType( super.entity ) == CharacterState.STAND )
			{
				// IF THERE IS NO CONTROLLER, TRIGGER A LOCAL ONE, IF ANY
				if( !_gauntlets.controller )
				{
					var gauntletControllerNode:GauntletControllerNode;
					var gauntletControllerNodes:NodeList = super.group.systemManager.getNodeList( GauntletControllerNode );
					
					// LOOP THROUGH CONTROLLERS; IF YOU ARE NEAR ONE AND FACING IT AND DO NOT HAVE A CONTROLLER PICKED UP ALREADY
					for( gauntletControllerNode = gauntletControllerNodes.head; gauntletControllerNode; gauntletControllerNode = gauntletControllerNode.next )
					{	
						if( !_gauntlets.controller )
						{
							spatial = gauntletControllerNode.spatial;
							
							// facing left and its on the right
							if((( charSpatial.scaleX > 0 && 0 < charSpatial.x - spatial.x && charSpatial.x - spatial.x < 100 ) 
								|| ( charSpatial.scaleX < 0 && 0 < spatial.x - charSpatial.x && spatial.x - charSpatial.x < 100 ))
								&& ( Math.abs( charSpatial.y - spatial.y ) < 80 ))
							{
								_gauntlets.controller = gauntletControllerNode.entity;
								_gauntlets.responder = gauntletControllerNode.gauntletController.responder;
							}
						}
					}
				}
				
				if( !_gauntlets.controller )
				{
					// LOOP THROUGH CONTROLLERS; IF YOU ARE ON A PLATFORM RESPONDER 
					for( gauntletControllerNode = gauntletControllerNodes.head; gauntletControllerNode; gauntletControllerNode = gauntletControllerNode.next )
					{	
						var entityList:EntityIdList = gauntletControllerNode.gauntletController.responder.get( EntityIdList );
						if( entityList )
						{
							var nodeId:Id = super.entity.get( Id );
							var name:String;
							
							for each( name in entityList.entities )
							{
								if( nodeId.id == name )
								{
									_gauntlets.controller = gauntletControllerNode.entity;
									_gauntlets.responder = gauntletControllerNode.gauntletController.responder;
								}
							}
						}
					}
				}
				
				SceneUtil.lockInput( super.group );
				CharUtils.setAnim( super.entity, Sword );
				
				var timeline:Timeline = super.entity.get( Timeline );
				timeline.handleLabel( "fire", firePulse );
				timeline.handleLabel( "hold", togglePanel );
				timeline.handleLabel( "ending", resetGauntletTargets );
			}
		}
		
		private function firePulse():void
		{
			// BLASTS
			var emitterEntity:Entity = super.group.getEntityById( "blastEmitter" );
			
			if( emitterEntity )
			{
				var emitter:Emitter = emitterEntity.get( Emitter );
				
				emitter.emitter.counter = new Blast( 20 );
				emitter.start = true;
				
				// RINGS
				emitterEntity = super.group.getEntityById( "ringEmitter" );
				
				var display:Display = super.entity.get( Display );
				var gloveDisplay:Display = _gloveFront.get( Display );
				
				var handPoint:Point = DisplayUtils.localToLocal( gloveDisplay.displayObject.sparks, display.container );
				var spatial:Spatial = emitterEntity.get( Spatial );
				spatial.x = handPoint.x;
				spatial.y = handPoint.y;
				
				Display( super.entity.get( Display )).moveToFront();
				
				emitter = emitterEntity.get( Emitter );
				
				emitter.emitter.counter = new Pulse( .25, 1 );
				emitter.start = true;
				
				AudioUtils.play( super.group, SoundManager.EFFECTS_PATH + blast );
			}
		}
		
		// TRIGGER THE RESPONDER
		private function togglePanel():void
		{
			var emitterEntity:Entity = super.group.getEntityById( "ringEmitter" );
			
			if( emitterEntity )
			{
				if( _gauntlets.responder )
				{
					var timeline:Timeline = _gauntlets.controller.get( Timeline );
					timeline.gotoAndStop( "on" );
					
					toggleAudio();
					var gauntletResponder:GauntletResponder = _gauntlets.responder.get( GauntletResponder );
					gauntletResponder.handler();
				}
				else
				{
					_gauntlets.fired.dispatch();
				}
				
				// STOP RING PULSE		
				var emitter:Emitter = emitterEntity.get( Emitter );
			
				emitter.emitter.counter = new ZeroCounter();
			}
		}
		
		// CHARGING GAUNTLETS IN PROCESSING SCENE
		public function chargeUp():void
		{
			addGlow( _gloveFront, "glow_front" );
			addGlow( _gloveBack, "glow_back" );
			
			firePulse();
			var timeline:Timeline = super.entity.get( Timeline );
			timeline.handleLabel( "ending", togglePanel );
			
			var dialog:Dialog = super.entity.get( Dialog );
			dialog.say( "got_power" );
			dialog.complete.addOnce( chargeComplete );
		}
		
		private function chargeComplete( dialogData:DialogData ):void
		{
			SceneUtil.lockInput( super.group, false );
		}
		
		// DEACTIVATORS
		private function toggleAudio():void
		{
			if( _gauntlets.controller && _gauntlets.controller.get( Audio ))
			{
				var audio:Audio = _gauntlets.controller.get( Audio );
				audio.playCurrentAction( TRIGGER );
			}
			
			if( _gauntlets.responder && _gauntlets.responder.get( Audio ))
			{
				audio = _gauntlets.responder.get( Audio );
				audio.playCurrentAction( TRIGGER );
			}
		}
		
		private function resetGauntletTargets():void
		{
			SceneUtil.lockInput( super.group, false );
			
			_gauntlets.controller = null;
			_gauntlets.responder = null;
		}
		
		override public function deactivate( node:SpecialAbilityNode ):void
		{
			if( _gloveFront )
			{
				var partLayer:PartLayer = _gloveFront.get( PartLayer );
				if(partLayer)
					partLayer.setInsert( CharUtils.ARM_FRONT, false );
				
				partLayer = _gloveBack.get( PartLayer );
				if(partLayer)
					partLayer.setInsert( CharUtils.ARM_BACK, false );
				
				SkinUtils.emptySkinPart( node.entity, SkinUtils.ITEM2 );
				node.entity.remove( Gauntlets );
				node.entity.group.removeEntity( super.group.getEntityById( "blastEmitter" ));
				node.entity.group.removeEntity( super.group.getEntityById( "ringEmitter" ));
				node.entity.group.removeEntity( super.group.getEntityById( "glow_front" ));
				node.entity.group.removeEntity( super.group.getEntityById( "glow_back" ));
			}
			
			var gauntletButton:Entity = super.group.getEntityById( "gauntletsButton" );
			var button:Button;
			if( gauntletButton )
			{
				button = gauntletButton.get( Button );
				button.isSelected = false;
			}
		} 
	}
}