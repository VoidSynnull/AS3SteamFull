package
{
	import com.poptropica.Assert;
	import com.poptropica.shellSteps.shared.ConfigureGame;
	import com.poptropica.shellSteps.shared.CreateConnection;
	import com.poptropica.shellSteps.shared.CreateCoreManagers;
	import com.poptropica.shellSteps.shared.CreateGame;
	import com.poptropica.shellSteps.shared.FileIO;
	import com.poptropica.shellSteps.shared.GetFirstScene;
	import com.poptropica.shellSteps.shared.LongTermMemoryRestore;
	import com.poptropica.shellSteps.shared.SetPlatform;
	import com.poptropica.shellSteps.shared.SetupInjection;
	import com.poptropica.shellSteps.shared.SetupManifestCheck;
	import com.poptropica.shellSteps.shared.StartGame;
	
	import flash.display.Sprite;
	import flash.events.Event;
	
	import ash.tick.FrameTickProvider;
	
	import engine.ShellApi;
	
	import game.util.ClassUtils;
	
	import org.osflash.signals.Signal;
	
	[SWF(frameRate='60', backgroundColor='#000000', wmode="gpu")]
	
	public class Shell extends Sprite
	{		
		public function Shell()
		{
			this._api = new ShellApi(this);
			addEventListener(Event.ADDED_TO_STAGE, onAddedToStage);
		}
				
		public function build():void
		{
			if(this._state == ShellState.UNBUILT)
			{
				this._state = ShellState.BUILDING;
				this.buildNextStep();
			}
		}
				
		public function getStepByIndex(index:int):ShellStep
		{
			if(index > -1 && index < this._steps.length)
			{
				return this._steps[index];
			}
			return null;
		}
		
		public function getStepIndex(step:ShellStep):int
		{
			return this._steps.indexOf(step);
		}
		
		public function getStepByClass(stepClass:Class):ShellStep
		{
			for each(var step:ShellStep in this._steps)
			{
				if(step is stepClass)
				{
					return step;
				}
			}
			return null;
		}
		
		public function addStep(step:ShellStep):ShellStep
		{
			return this.addStepAt(step, -1);
		}
		
		public function addStepAt(step:ShellStep, index:int):ShellStep
		{
			Assert.assert(this._state == ShellState.UNBUILT, "Shell already built");
			
			if(this._state != ShellState.UNBUILT) return null;
			
			Assert.assert(step._shell == null, "Step already added.");
			
			if(step != null && !step._shell)
			{
				if(index > -1 && index < this._steps.length)
				{
					this._steps.splice(index, 0, step);
				}
				else
				{
					this._steps.push(step);
				}
				step._shell = this;
				return step;
			}
			
			Assert.assert(step != null, "Step is null");
			
			return null;
		}
		
		/**
		 * Allows you to pass a list of ShellSteps as opposed to adding each individually. 
		 * @param steps
		 */
		public function queueSteps(steps:Vector.<ShellStep>):void
		{
			for (var i:int = 0; i < steps.length; i++) 
			{
				addStep(steps[i]);
			}
		}

		public function removeStep(step:ShellStep):ShellStep
		{
			if(this._state != ShellState.UNBUILT) return null;
			
			if(step && step._shell == this)
			{
				this._steps.splice(this._steps.indexOf(step), 1);
				step._shell = null;
				return step;
			}
			return null;
		}
				
		/**
		 * Method called to construct application based on ShellSteps.
		 * ShellSteps are added here in the appropriate order. 
		 * This method should be overridden by applications and supplied with the appropriate ShellSteps
		 */
		protected function construct():void
		{
			this.addStep(new SetupInjection());			// Setup injection for ShellApi so subsequent classes can access ShellApi via injection
			this.addStep(new SetPlatform());			// Set platform specific flags, assign platform class implementing IPlatform
			this.addStep(new CreateCoreManagers());		// Create essential core managers
			this.addStep(new LongTermMemoryRestore());	// Retrieve long term memory from LSO, restore stored profile data
			this.addStep(new FileIO());					// Create file loading facilities
			this.addStep(new SetupManifestCheck());		// FOR DEBUG : setup manifest verification if AppConfig.verifyPathInManifest == true
			this.addStep(new CreateConnection());		// Used if you need to connect to server
			this.addStep(new ConfigureGame());			// Load game configuration (game.xml) and apply settings appropriately
			this.addStep(new CreateGame());				// Create game specific managers
			this.addStep(new GetFirstScene());			// Determine first scene
			this.addStep(new StartGame());				// Start tick update, load first scene
			
			this.build();
		}
		
		public function resetPostBuildProcess():void
		{
			_postProcessBuildingStarted = false;
		}
		// if there is to be a second set of building after logging in
		public function postBuildProcess():void
		{
			if(_state == ShellState.BUILT && !_postProcessBuildingStarted)
			{
				_postProcessBuildingStarted = true;
				_steps = new Vector.<ShellStep>();
				_state = ShellState.UNBUILT;
				_currentStep = -1;
				constructPostProcessBuildSteps();
				build();
			}
			else
			{
				buildNextStep();
			}
		}
		
		protected function constructPostProcessBuildSteps():void
		{
			
		}
		
		private function onAddedToStage(event:Event):void
		{
			removeEventListener(Event.ADDED_TO_STAGE, onAddedToStage);
			this.construct();
		}
		
		internal function buildNextStep():void
		{
			if(++this._currentStep < this._steps.length)
			{
				const step:ShellStep = this._steps[this._currentStep];
				
				//Traces out what version of Shell that's running (IosShell, AndroiShell, OnlineShell, etc.), #/# step number, and current step name.
				const shellClassParts:Array = ClassUtils.getNameByObject(this).split("::"); //Depending on the package, there may not be a "::".
				trace(shellClassParts[1] ? shellClassParts[1] : shellClassParts[0], "::", this._currentStep + 1, "/", this._steps.length, ClassUtils.getNameByObject(step).split("::")[1]);
				
				this._stepChanged.dispatch(step);
				step.buildStep();
			}
			else
			{
				this._state = ShellState.BUILT;
				this._complete.dispatch(this);
				
				this._complete.removeAll();
				this._stepChanged.removeAll();
			}
		}
		
		public function get state():String { return this._state; }
		public function get shellApi():ShellApi { return this._api; }
		public function get stepIndex():int { return this._currentStep; }
		public function get stepChanged():Signal { return this._stepChanged; }
		public function get complete():Signal { return this._complete; }
		
		public var _tickProvider:FrameTickProvider;
		public var params:Object;
		
		private var _state:String = ShellState.UNBUILT;
		private var _currentStep:int = -1;
		private var _steps:Vector.<ShellStep> = new Vector.<ShellStep>();
		private var _stepChanged:Signal = new Signal(ShellStep);
		private var _complete:Signal = new Signal(Shell);
		private var _postProcessBuildingStarted:Boolean = false;
		internal var _api:ShellApi;
	}
}
