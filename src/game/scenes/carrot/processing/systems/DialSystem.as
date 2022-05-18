package game.scenes.carrot.processing.systems
{
	import ash.core.Engine;
	import ash.core.NodeList;
	import ash.core.System;
	
	import engine.components.Spatial;
	
	import game.scenes.carrot.processing.nodes.DialNode;
	import game.systems.SystemPriorities;
	
	import org.osflash.signals.Signal;
	
	public class DialSystem extends System
	{			
		public function DialSystem()
		{
			super._defaultPriority = SystemPriorities.update;
			moved = new Signal( String );
			_state = "off";
			_changedState = false;
			ready = false;
		}
		
		override public function addToEngine( systemsManager:Engine ):void
		{
			_nodes = systemsManager.getNodeList( DialNode );
			
		}
		
		override public function update( time:Number ):void
		{
			var node:DialNode;
			var spatial:Spatial;
			var label:String;
					
			for ( node = _nodes.head; node; node = node.next )
			{
				spatial = node.spatial;
				
				if( spatial.rotation != DIAL_STOP_POSITION && ready )
				{
					spatial.rotation -= DIAL_ROTATION_STEP;

					if( spatial.rotation <= MAX_VAPORIZE && spatial.rotation > MIN_VAPORIZE )
					{
						label = "vaporize";
						if( _state != label )
						{
							_state = "vaporize";
							_changedState = true;
						}
					}
					else if( spatial.rotation <= MIN_VAPORIZE && spatial.rotation > MIN_LIQUIFY )
					{
						label = "liquify";
						if( _state != label )
						{
							_state = "liquify";
							_changedState = true;
						}
					}
					else if( spatial.rotation <= MIN_LIQUIFY && spatial.rotation > MIN_BLEND )
					{
						label = "blend";
						if( _state != label )
						{
							_state = "blend";
							_changedState = true;
						}
					}
					else if( spatial.rotation <= MIN_BLEND && spatial.rotation > MIN_MIX )
					{
						label = "mix";
						if( _state != label )
						{
							_state = "mix";
							_changedState = true;
						}
					}
					else if( spatial.rotation <= MIN_MIX && spatial.rotation > DIAL_STOP_POSITION )
					{
						label = "off"; 
						if( _state != label )
						{
							_state = "off";
							_changedState = true;
						}
					}
					else if( spatial.rotation <= DIAL_STOP_POSITION )
					{
						label = "off";
						_changedState = true;
						spatial.rotation = DIAL_STOP_POSITION;
					}
					
					if( _changedState )
					{
						moved.dispatch( label );
					}
					_changedState = false;
				}
				
				else 
				{
					ready = false;
				}
			}
		}
		
		override public function removeFromEngine( systemsManager:Engine ):void
		{
			systemsManager.releaseNodeList( DialNode );
			_nodes = null;
			moved.removeAll();
			moved = null;
		}
		
		public var moved:Signal;
		public var ready:Boolean;
			
		private var _nodes : NodeList;
		private var _state:String;
		private var _changedState:Boolean;
		
		private static const DIAL_ROTATION_STEP:Number = .5;
		private static const DIAL_STOP_POSITION:int = -50;
		
		private static const MIN_MIX:int = -33;
		private static const MIN_BLEND:int = 0;
		private static const MIN_LIQUIFY:int = 51;
		private static const MIN_VAPORIZE:int = 111;
		private static const MAX_VAPORIZE:uint = 180;
	}
}