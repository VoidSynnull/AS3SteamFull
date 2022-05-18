package game.components.ui
{
	import flash.utils.Dictionary;
	
	import ash.core.Component;
	import ash.core.Entity;
	
	import engine.components.Spatial;
	
	import game.data.display.SpatialData;
	import game.data.ui.GestureState;
	
	public class Gesture extends Component
	{
		public function get up():GestureState{return states[GestureState.UP];}
		public function set up(state:GestureState):void{ states[GestureState.UP] = state;}
		
		public function get down():GestureState{return states[GestureState.DOWN];}
		public function set down(state:GestureState):void{ states[GestureState.DOWN] = state;}
		
		// up and down are common states so they get quick access vars
		
		public var states:Dictionary;
		
		private var _state:GestureState;
		
		public function set state(gestureState:GestureState):void
		{
			_state = gestureState;
			if(states[_state.state] == null)
				states[_state.state] = _state;
		}
		
		public function get state():GestureState{return _state;}
		
		private var _animation:Entity;
		
		public function get animation():Entity{return _animation;}
		
		public var ripple:Entity;
		
		public function set animation(entity:Entity):void
		{
			_animation = entity;
			var spatial:Spatial = entity.get(Spatial);
			states = new Dictionary();
			up = new GestureState(GestureState.UP, new SpatialData(spatial));
			down = new GestureState(GestureState.DOWN, new SpatialData(spatial));
		}
		
		public function Gesture(entity:Entity, ripple:Entity = null)
		{
			this.animation = entity;
			this.ripple = ripple;
		}
		
		public function getState(state:String):GestureState
		{
			return states[state];
		}
	}
}