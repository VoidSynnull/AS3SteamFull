package game.scenes.myth.labyrinth.popups
{
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.events.Event;
	
	import ash.core.Entity;
	
	import engine.components.Id;
	import engine.components.Interaction;
	import engine.util.Command;
	
	import game.components.timeline.Timeline;
	import game.creators.ui.ButtonCreator;
	import game.data.TimedEvent;
	import game.scenes.myth.labyrinth.components.BoneComponent;
	import game.ui.popup.Popup;
	import game.util.SceneUtil;
	
	import org.osflash.signals.Signal;
	
	public class Bones extends Popup
	{
		public function Bones( container:DisplayObjectContainer=null )
		{
			super(container);
		}
		
		override public function destroy():void
		{
			complete.removeAll();
			complete = null;
			
			_bones = null;
			
			super.destroy();	
		}
		
		override public function init( container:DisplayObjectContainer=null ):void
		{
			complete = new Signal();
			_bones = new Vector.<Entity>;
			
			super.darkenBackground = true;
			super.groupPrefix = "scenes/myth/labyrinth/";
			super.init( container );
			super.autoOpen = false;
			load();
		}
		
		override public function load():void
		{
			super.loadFiles([ "bones.swf" ], false, true, loaded );
		}
		
		override public function loaded():void
		{
			super.screen = super.getAsset( "bones.swf", true ) as MovieClip;
			super.layout.centerUI( super.screen.content );
			loadCloseButton();

			super.loaded();
			super.open();
			
			arrangeBones();
		}
		
		private function arrangeBones():void
		{
			var entity:Entity;
			var clip:MovieClip;
			var number:int;
			var interaction:Interaction;
			var timeline:Timeline;
			
			for( number = 0; number < 9; number ++ )
			{
				clip = MovieClip( MovieClip( super.screen.content ).getChildByName( "b" + number ));
				
				entity = ButtonCreator.createButtonEntity( clip, this );
				interaction = entity.get( Interaction );
				entity.add( new Id( "keeper" + number )).add( new BoneComponent( true ));
			
				_keeperOnCount++;
				
				timeline = entity.get( Timeline );
				timeline.gotoAndStop( 0 );
				timeline.labelReached.add( Command.create( labelHandler, entity ));
				
				interaction.downNative.add( Command.create( removeBone, entity ));
				
				_bones.push( entity );
			}
			
			for( number = 0; number < 6; number ++ )
			{
				clip = MovieClip( MovieClip( super.screen.content ).getChildByName( "n" + number ));
				
				entity = ButtonCreator.createButtonEntity( clip, this );
				interaction = entity.get( Interaction );
				entity.add( new Id( "tosser" + number )).add( new BoneComponent());
				
				timeline = entity.get( Timeline );
				timeline.gotoAndStop( 0 );
				timeline.labelReached.add( Command.create( labelHandler, entity ));
				interaction.downNative.add( Command.create( removeBone, entity ));
				_bones.push( entity );
			}
		}
		
		private function labelHandler( label:String, entity:Entity ):void
		{
			var bone:BoneComponent = entity.get( BoneComponent );
			var timeline:Timeline = entity.get( Timeline );
			
			switch( label )
			{
				case "off":
					timeline.paused = true;
					bone.transition = false;
					break;
				case "on":
					timeline.gotoAndStop( 0 );
					bone.transition = false;
					break;
			}
		}
		
		private function removeBone( e:Event, entity:Entity ):void
		{
			var number:int;
			var timeline:Timeline = entity.get( Timeline );
			var bone:BoneComponent = entity.get( BoneComponent );
			var interaction:Interaction = entity.get( Interaction );
			
			if( !bone.transition )
			{
				bone.transition = true;
				timeline.paused = false;
				super.shellApi.triggerEvent( "pickup_bone" );
				
				// flip the on state
				if( bone.on )
				{
					bone.on = false;
				}
				else
				{
					bone.on = true;
				}			
				
				// evaluate this answer
				if( bone.keeper && bone.on )
				{
					_keeperOnCount++;	
				}
				else if( bone.keeper && !bone.on )
				{
					_keeperOnCount--;
				}
				else if( !bone.keeper && bone.on )
				{
					_tosserOffCount--;
				}
				else if( !bone.keeper && !bone.on )
				{
					_tosserOffCount++;
				}
				
				// check puzzle completion
				if( _tosserOffCount == TOSSER_GOAL && _keeperOnCount == KEEPER_GOAL )
				{
					for( number = 0; number < _bones.length; number ++ )
					{
						_bones[ number ].remove( Interaction );
					}
					SceneUtil.lockInput( this );
					SceneUtil.addTimedEvent( this, new TimedEvent( 1, 1, completeBones ));
				}
			}
		}
		
		private function completeBones():void
		{
			complete.dispatch();
		}
		
		public var complete:Signal;
		
		private var _bones:Vector.<Entity>;
		private const TOSSER_GOAL:uint = 6;
		private const KEEPER_GOAL:uint = 9;
		private var _keeperOnCount:uint = 0;
		private var _tosserOffCount:uint = 0;
	}
}