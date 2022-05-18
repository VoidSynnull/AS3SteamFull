// Used by:
// Card 3338 using hair p_6birthday_boy
// Card 3339 using hair p_6birthday_girl

package game.data.specialAbility.store
{
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.geom.Point;
	
	import ash.core.Entity;
	
	import engine.components.Display; 
	import engine.components.Spatial;
	
	import game.components.motion.VelocityListener;
	import game.components.timeline.Timeline;
	import game.components.timeline.TimelineClip;
	import game.creators.entity.EmitterCreator;
	import game.data.animation.Animation;
	import game.data.specialAbility.SpecialAbility;
	import game.nodes.specialAbility.SpecialAbilityNode;
	import game.particles.emitter.specialAbility.ConfettiBlast;
	import game.systems.motion.VelocityListenerSystem;
	import game.util.CharUtils;
	import game.util.EntityUtils;
	
	import org.flintparticles.twoD.emitters.Emitter2D;
	
	/*
	* Poptropica Birthday Hat with animation and particles
	*/
	public class BirthdayHat extends SpecialAbility
	{
		override public function init( node:SpecialAbilityNode ):void
		{
			return; // TODO :: this whole hat appears to be busted.
			
			super.init(node);
			
			if(_partType == null)
			{
				trace("BirthdayHat :: ERROR : You must pass the part type as a parameter");
				return;
			}
			
			partEntity = CharUtils.getPart(node.entity, _partType);
			activeobj = EntityUtils.getChildById(node.entity, "active_obj");
			if( activeobj )
			{
				timeline = activeobj.get(Timeline);
				timeline.gotoAndStop("stop");
			}
			
			if(!node.entity.get(VelocityListener))
			{
				var velocityListener:VelocityListener = new VelocityListener(velocityUpdate, false);
				node.entity.add(velocityListener);	
			}
			// Add the Velocity Listener Sytem if it's not there already
			if( !group.getSystem( VelocityListenerSystem ) )
			{
				group.addSystem( new VelocityListenerSystem() );
			}
		}
				
		override public function activate( node:SpecialAbilityNode ):void
		{
			if ((_partType) && ( !super.data.isActive ))
			{	
				//timeline = partEntity.get(Children).children[0].get(Timeline);
				if(isOpen)
				{
					doClose();
				}
				else
				{
					doOpen();
					addParticles();
				}
			}
		}
		
		override public function deactivate( node:SpecialAbilityNode ):void
		{
			node.entity.remove(VelocityListener);
		}
		
		// Functions for opening and closing
		private function doOpen():void
		{	
			super.setActive( true );
			timeline.gotoAndPlay("open");
			timeline.handleLabel("close", openComplete);
		}
		
		private function openComplete():void
		{
			timeline.stop();
			isOpen = true;
			super.setActive( false );
		}
		
		private function doClose():void
		{	
			super.setActive( true );
			timeline.gotoAndPlay("close");
			timeline.handleLabel(Animation.LABEL_ENDING, closeComplete);
		}
		
		private function closeComplete():void
		{
			timeline.stop();
			isOpen = false;
			super.setActive( false );
		}
		
		private function addParticles():void
		{
			// Add the particles
			_emitter = new ConfettiBlast();
			_emitter.init();
			var container:DisplayObjectContainer = super.entity.get(Display).container;
			
			// Get the Spatial of the hand and use the X,Y to place our object
			var charspatial:Spatial = super.entity.get(Spatial);
			
			var xPos:Number = charspatial.x;
			var yPos:Number = charspatial.y - 130;
			
			_emitterEntity = EmitterCreator.create( group, container, _emitter as Emitter2D, xPos, yPos );
		}
		
		// Point the "6" in the right direction
		public function velocityUpdate(velocityPoint:Point):void
		{	
			if(velocityPoint.x > 0)
			{
				activeobj.get(TimelineClip).mc.scaleX = -1;
			} else if(velocityPoint.x < 0) {
				activeobj.get(TimelineClip).mc.scaleX = 1;
			}
		}
		
		public var _partType:String;
		
		private var partEntity:Entity;
		private var partClip:MovieClip;
		private var activeobj:Entity;
		private var timeline:Timeline;
		private var timelineMC:MovieClip;
		private var isOpen:Boolean = false;
		private var _emitter:Object;
		private var _emitterEntity:Entity;
	}
}