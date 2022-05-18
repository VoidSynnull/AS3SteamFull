package game.scenes.con3.shared.power
{
	import flash.utils.Dictionary;
	
	import ash.core.Component;
	import ash.core.Entity;
	
	import org.osflash.signals.Signal;
	
	public class Power extends Component
	{
		//Input
		internal var _numSources:uint = 0;
		internal var _sources:Dictionary = new Dictionary();
		internal var _input:Number = 0;
		internal var _inputConverter:PowerInputConverter = new PowerInputConverter();
		internal var _power:Number = 0;
		internal var _powered:Boolean = false;
		internal var _on:Signal = new Signal(Entity);
		internal var _off:Signal = new Signal(Entity);
		
		//Output
		internal var _source:String;
		internal var _output:Number = 0;
		internal var _outputConverter:PowerOutputConverter = new PowerOutputConverter();
		
		public function Power(input:Number = 0, power:Number = 0)
		{
			this.input = input;
			this.power = power;
		}
		
		/**
		 * The amount of input power the Entity has.
		 */
		public function get input():Number { return this._input; }
		public function set input(input:Number):void
		{
			if(isFinite(input))
			{
				if(input < 0)
				{
					input = 0;
				}
				
				this._input = input;
			}
		}
		
		public function get on():Signal { return this._on; }
		public function get off():Signal { return this._off; }
		
		public function get numSources():uint { return this._numSources; }
		
		/**
		 * The amount of input power the Entity needs to be powered.
		 */
		public function get power():Number { return this._power; }
		public function set power(power:Number):void
		{
			if(isFinite(power))
			{
				if(power < 0)
				{
					power = 0;
				}
				
				this._power = power;
			}
		}
		
		/**
		 * A PowerInputConverter instance that converts its inputs into power.
		 * <p>Power.power = converter.convert(inputs);</p>
		 */
		public function get inputConverter():PowerInputConverter { return this._inputConverter; }
		public function set inputConverter(inputConverter:PowerInputConverter):void
		{
			if(!inputConverter) inputConverter = new PowerInputConverter();
			this._inputConverter = inputConverter;
		}
		
		public function get powered():Boolean { return this._input >= this._power; }
		
		public function getSources():Array
		{
			const sources:Array = [];
			for(var source:String in this._sources)
			{
				sources.push(source);
			}
			return sources;
		}
		
		public function hasSource(source:String):Boolean
		{
			return this._sources[source];
		}
		
		public function addSource(source:String):Boolean
		{
			if(source && !this._sources[source])
			{
				this._sources[source] = true;
				++this._numSources;
				return true;
			}
			return false;
		}
		
		public function addSources(sources:Array):Boolean
		{
			if(!sources) return false;
			
			var success:Boolean = true;
			for each(var source:String in sources)
			{
				if(!this.addSource(source))
				{
					success = false;
				}
			}
			return success;
		}
		
		public function removeSource(source:String):Boolean
		{
			if(source && this._sources[source])
			{
				delete this._sources[source];
				--this._numSources;
				return true;
			}
			return false;
		}
		
		public function removeSources(sources:Array = null):Boolean
		{
			var source:String;
			
			if(sources)
			{
				var success:Boolean = true;
				for each(source in sources)
				{
					if(!this.removeSource(source))
					{
						success = false;
					}
				}
				return success;
			}
			else
			{
				for(source in this._sources)
				{
					this.removeSource(source);
				}
				return true;
			}
		}
		
		public function get source():String { return this._source; }
		public function set source(source:String):void { this._source = source; }
		
		public function get output():Number { return this._output; }
		
		public function get outputConverter():PowerOutputConverter { return this._outputConverter; }
		public function set outputConverter(outputConverter:PowerOutputConverter):void
		{
			if(!outputConverter) outputConverter = new PowerOutputConverter();
			this._outputConverter = outputConverter;
		}
	}
}