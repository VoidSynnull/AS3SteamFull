package game.components.actionChain {
	
	import ash.core.Component;
	
	import engine.group.Group;
	
	import game.nodes.specialAbility.SpecialAbilityNode;
	import game.systems.actionChain.ActionCommand;
	import game.util.SceneUtil;

	// Usually only one action will be executing at a time, but by using noWait
	public class ActionExecutor extends Component {

		public var curBatch:int;

		// This is obnoxious but we need to pass actions their group in case they need to
		// access special systems to get their jobs done. In theory this could be handled
		// by the user of the Action, but the idea is to make the Action system as easy to use as possible.
		private var group:Group;
		private var _node:SpecialAbilityNode;

		private var head:ExecutionItem;

		/**
		 * Individual actions, when run apart from scenes, have lockInput variables which can lock the scene.
		 * However if two are run in sequence, the first one that finishes will unlock the entire scene.
		 * This counts the number of locks and only unlocks when it reaches 0.
		 */
		private var lockCount:int;

		public function ActionExecutor( group:Group ) {

			this.group = group;
			lockCount = 0;
			curBatch = 0;

		} //

		public function start(node:SpecialAbilityNode):void {
			_node = node;
			curBatch++;

		} //

		// Even ending the current batch should invalidate all callbacks currently pending.
		public function stop():void {

			curBatch++;

		} //

		// A bit messy at the moment. Clean up "later" teehee.
		public function update( time:Number ):void {

			for( var exec:ExecutionItem = head; exec != null; exec = exec.next ) {

				if ( exec.state == ExecutionItem.ACTING ) {

					if ( exec.action.update != null ) {
						exec.action.update( time );
					}

				} else if ( exec.state == ExecutionItem.PREACTION ) {

					exec.timer -= time;
					if ( exec.timer <= 0 ) {
						executeItem( exec );
					} //

				} else if ( exec.state == ExecutionItem.POSTACTION ) {

					exec.timer -= time;
					// The action completed earlier but was on an endDelay wait.
					if ( exec.timer <= 0 ) {

						if ( exec.batchId == this.curBatch ) {

							///trace( "endAction: " + (lockCount-1) );
							//trace( "lockinput? " + exec.action.lockInput );
							if ( exec.action.lockInput && --lockCount <= 0 ) {
							//	trace( "UNLOCKING" );
								lockCount = 0;
								SceneUtil.lockInput( this.group, false );
							}
							if ( exec.callback != null ) {
								exec.callback( exec.action );
							}

						} //

						cutItem( exec );

					} //

				} else if ( exec.state == ExecutionItem.COMPLETE ) {

					if ( exec.batchId == this.curBatch ) {
						execComplete( exec );
						if ( exec.state == ExecutionItem.POSTACTION ) {
							continue;
						}
					} //

					cutItem( exec );

				} else {
				} // End-if.

			} //

		} //

		/**
		 * An action's execution is complete, though it may still have an endDelay.
		 */
		public function execComplete( exec:ExecutionItem ):void {

			if ( exec.action.endDelay > 0 ) {

				exec.state = ExecutionItem.POSTACTION;
				exec.timer = exec.action.endDelay;

			} else {

				//trace( "endAction: " + (lockCount-1) );
			//	trace( "lockinput? " + exec.action.lockInput );

				//trace( "LOCK: " + lockCount );
				if ( exec.action.lockInput && --lockCount <= 0 ) {
					//trace( "UNLOCKING" );
					lockCount = 0;
					SceneUtil.lockInput( this.group, false );
				}
				// execution entirely complete.
				if ( exec.callback != null ) {
					exec.callback( exec.action );
				}

			} //

		} //

		// Add an action to be executed.
		public function addAction( action:ActionCommand, callback:Function ):void {

			var exec:ExecutionItem = new ExecutionItem( action, callback, curBatch );

			exec.next = head;
			if ( head ) {
				head.prev = exec;
			}
			head = exec;

			if ( action.lockInput ) {
				lockCount++;
				//trace( "startAction: " + lockCount );
				SceneUtil.lockInput( group, true );
			} //

			if ( action.startDelay > 0 ) {

				exec.state = ExecutionItem.PREACTION;
				exec.timer = action.startDelay;

			} else {

				executeItem( exec );

			} // End-if.

		} //

		private function executeItem( exec:ExecutionItem ):void {

			exec.state = ExecutionItem.ACTING;
			exec.action.preExecute( exec.actionDone, group, _node );

		} //

		private function cutItem( e:ExecutionItem ):void {

			if ( e == head ) {

				head = e.next;
				if ( head ) {
					head.prev = null;
				}

			} else {

				e.prev.next = e.next;				// since e is not head, e better have a prev.
				if ( e.next ) {
					e.next.prev = e.prev;
				}

			} //

		} //

		public function addActions( actions:Vector.<ActionCommand>, callback:Function ):void {

			var a:ActionCommand;
			var item:ExecutionItem;

			for( var i:int = actions.length-1; i >= 0; i-- ) {

				a = actions[i];
				item = new ExecutionItem( a, callback, curBatch );

				item.next = head;
				if ( head ) {
					head.prev = item;
				}
				head = item;

				if ( a.startDelay > 0 ) {

					item.timer = a.startDelay;
					item.state = ExecutionItem.PREACTION;

				}  else {

					executeItem( item );

				} // End-if.

			} //

		} //

	} // End ActionList
	
} // End package