package engine.components {
	
	import com.greensock.TweenMax;
	
	import flash.utils.Dictionary;
	
	import ash.core.Component;
	
	public class Tween extends Component {
		
		public var tweens:Vector.<TweenMax>;
		public var name_lookup:Dictionary;
		
		private var paused:Boolean = false;
		
		public function Tween()
		{
			tweens = new Vector.<TweenMax>();
			name_lookup = new Dictionary(true);
		}
		
		override public function destroy():void
		{
			killAll();
			
			name_lookup = null;
			tweens = null;
		}

		public function killAll():void
		{
			for each(var tween:TweenMax in tweens)
			{
				tween.kill();
			}
			tweens.length = 0;
			
			super.destroy();
		}
		
		public function removeTweenByName(name:String):Boolean
		{
			var tween:TweenMax = name_lookup[name];
			
			if(tween)
			{
				delete name_lookup[name];
				tweens.splice(tweens.indexOf(tween), 1);
				tween.kill();
				return true;
			}
			return false;
		}
		
		public function to(component:*, duration:Number, vars:Object, name:String = ""):TweenMax
		{
			return addTween(TweenMax.to(component, duration, vars), name);
		}
		
		public function from(component:*, duration:Number, vars:Object, name:String = ""):TweenMax
		{
			return addTween(TweenMax.from(component, duration, vars), name);
		}
		
		public function fromTo(component:*, duration:Number, fromVars:Object, toVars:Object, name:String = ""):TweenMax
		{
			return addTween(TweenMax.fromTo(component, duration, fromVars, toVars), name);
		}
		
		public function pauseAllTweens(pause:Boolean = true):void
		{
			paused = pause;
		}
		
		public function getTweenByName(name:String):TweenMax
		{
			if(name_lookup[name] != null)
			{
				return name_lookup[name] as TweenMax;
			}
			return null;
		}
		
		public function get tweening():Boolean
		{
			return(tweens.length > 0);
		}
		
		public function getTweensByComponent(component:Component):Vector.<TweenMax>
		{
			var return_vector:Vector.<TweenMax> = new Vector.<TweenMax>();
			for each(var tween:TweenMax in tweens)
			{
				if(tween.target == component)
				{
					return_vector.push(tween);
				}
			}
			return return_vector;
		}
		
		public function updateTweenByName(name:String, vars:Object, resetDuration:Boolean = false):void
		{
			var tween:TweenMax = getTweenByName(name);
			if(tween)
			{
				tween.updateTo(vars, resetDuration);
				if(vars.hasOwnProperty("delay")) tween.delay = vars.delay; 
				if(tween.totalProgress == 1)
				{
					tween.restart();
					tween.pause();
				}
			}
		}
	
		public function updateDelta(delta:Number):void
		{
			if(!paused && tweens != null)
			{
				var i:uint = 0;
				for each(var tween:TweenMax in tweens)
				{
					if(tween.totalProgress < 1)
					{	
						if(tween.delay > 0){
							tween.delay -= delta;
						}else{
							tween.totalTime += delta;
						}
					}
					else
					{
						tweens.splice(i, 1);
						i--;
					}
					i++;
				}
			}
		}
		
		protected function addTween(tween:TweenMax, name:String):TweenMax
		{
			tween.pause();
			if(tweens == null){
				tweens = new Vector.<TweenMax>();
			}	
			tweens.push(tween);
			if(name.length > 0)
			{
				name_lookup[name] = tween;
			}
			return tween;
		}
		
	}
}