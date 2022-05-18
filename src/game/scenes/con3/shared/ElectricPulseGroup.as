package game.scenes.con3.shared
{
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.geom.Point;
	
	import ash.core.Entity;
	
	import engine.components.Audio;
	import engine.components.AudioRange;
	import engine.components.Id;
	import engine.components.Interaction;
	import engine.components.Motion;
	import engine.components.Spatial;
	import engine.creators.InteractionCreator;
	import engine.group.Group;
	import engine.util.Command;
	
	import game.components.entity.Dialog;
	import game.components.entity.Sleep;
	import game.components.motion.FollowTarget;
	import game.components.timeline.BitmapSequence;
	import game.components.timeline.Timeline;
	import game.creators.entity.BitmapTimelineCreator;
	import game.creators.ui.ToolTipCreator;
	import game.data.scene.hit.MovingHitData;
	import game.data.specialAbility.SpecialAbilityData;
	import game.data.specialAbility.islands.poptropicon.PowerGlove;
	import game.scene.template.AudioGroup;
	import game.util.CharUtils;
	import game.util.EntityUtils;
	import game.util.PerformanceUtils;
	
	public class ElectricPulseGroup extends Group
	{		
		private const LIFT:String				= 		"lift";
		private const OFF:String				=		"off";
		private const PANEL:String				= 		"panel"; 
		
		private var _panelSequence:BitmapSequence;
		
		public function ElectricPulseGroup()
		{
			super();
		}
		
		override public function destroy():void
		{
			if( _panelSequence )
			{
				_panelSequence.destroy();
				_panelSequence = null;
			}
			super.destroy();
		}
		/**
		 * CREATE PANELS - create the pulse glove receptive entities.
		 * 
		 * @param panelClip - MovieClip for the timelined interactive asset
		 * @param group - Group owning group.
		 * @param container - DisplayObjectContainer layer to add entities to.
		 * @param pulseHandler - Function for handling end of pulse charge.
		 * @param tabeResponderName - String for the name of response entity for panels woithout "lift" in the name, should already be created.
		 * @param liftResponderName - String for the name of response entity for panels with "lift" in the name, should already be created.
		 * @param endMovementFunction - Function for end of lift motion, optional.
		 */
		public function createPanels( panelClip:MovieClip, group:Group, container:DisplayObjectContainer, pulseHandler:Function, tabResponderName:String = null, liftResponderName:String = null, endMovementFunction:Function = null ):void
		{			
			var audioGroup:AudioGroup = group.getGroupById( AudioGroup.GROUP_ID ) as AudioGroup;
			var clip:DisplayObject;
			var controller:Entity;
			var gauntletController:GauntletControllerComponent;
			var followTarget:FollowTarget;
			var gauntletResponder:GauntletResponder;
			var interaction:Interaction;
			var motion:Motion;
			var movingHitData:MovingHitData;
			var number:String;
			var responder:Entity;
			var spatial:Spatial;
			var controllerSpatial:Spatial;
			
			for( var index:int = container.numChildren - 1; index > -1; --index )
			{
				clip = container.getChildAt(index);
				
				if( clip.name.indexOf( PANEL ) > -1 )
				{
					// CREATE THE CONTROLLER PANEL
					number = clip.name.substr( clip.name.length - 1 );
					controller = EntityUtils.createSpatialEntity( group, clip );
					
					if( !_panelSequence )
					{
						_panelSequence = BitmapTimelineCreator.createSequence( panelClip, group, PerformanceUtils.defaultBitmapQuality + 0.3);
					}
					BitmapTimelineCreator.convertToBitmapTimeline( controller, clip as MovieClip, true, _panelSequence );
					controller.add( new Id( clip.name )); 
					
					var timeline:Timeline = controller.get( Timeline );
					timeline.gotoAndStop( OFF );
					
					
					// ADD AUDIO TO CONTROLLER
					audioGroup.addAudioToEntity( controller );
					if( controller.has( Audio ))
					{
						controller.add( new AudioRange( 600 ));
					}
					ToolTipCreator.addToEntity( controller );
					
					interaction = InteractionCreator.addToEntity( controller, [ InteractionCreator.CLICK ]);
					
					gauntletResponder = new GauntletResponder();					
					gauntletResponder.offset = new Point( clip.width / 2, 0 );
					
					gauntletController = new GauntletControllerComponent();
					
					// SETUP IT'S RESPONDER, IF THERE IS ONE
					if( liftResponderName || tabResponderName )
					{
						if( clip.name.indexOf( LIFT ) > -1 )
						{
							responder = group.getEntityById( liftResponderName + number );
							spatial = responder.get( Spatial );
							controllerSpatial = controller.get( Spatial );
							
							followTarget = new FollowTarget( spatial );
							followTarget.offset = new Point( 0, -controllerSpatial.height / 4 );
							controller.add( followTarget );
							if( controller.get( Sleep ))
							{
								Sleep( controller.get( Sleep )).ignoreOffscreenSleep = true;
							}
							
							gauntletResponder.offset.y = -100;
						}
						
						else
						{
							responder = group.getEntityById( tabResponderName + number );
							spatial = responder.get( Spatial );
						}
						
						interaction.click.add( Command.create( moveToPanel, responder ));	
						
						gauntletResponder.endPoint = new Point( spatial.x, spatial.y );
						gauntletResponder.handler = Command.create( pulseHandler, responder );
						responder.add( gauntletResponder );
						
						audioGroup.addAudioToEntity( responder );
						if( responder.has( Audio ))
						{
							responder.add( new AudioRange( 600 ));
						}
						
						gauntletController.responder = responder;
						controller.add( gauntletController );
						
						if( endMovementFunction )
						{
							movingHitData = responder.get( MovingHitData );
							movingHitData.reachedPoint.add( Command.create( endMovementFunction, controller, responder ));
						
							motion = responder.get( Motion );
							motion.maxVelocity = new Point( 0, 0 );
						}
					}
				}
			}
		}
		
		private function moveToPanel( controller:Entity, responder:Entity ):void
		{
			if( CharUtils.hasSpecialAbility( shellApi.player, PowerGlove))
			{
				var gauntlets:Gauntlets = shellApi.player.get( Gauntlets );
				
				gauntlets.controller = controller;
				gauntlets.responder = responder;
				
				CharUtils.triggerSpecialAbility( shellApi.player );
			}
			else
			{
				var dialog:Dialog = shellApi.player.get( Dialog );
				dialog.sayById( "no_power" );
			}
		}
	}
}