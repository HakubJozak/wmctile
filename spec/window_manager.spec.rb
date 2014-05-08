require_relative '../lib/wmctile'

describe 'WindowManager' do
	wm = nil
	before(:all) do
		# override dmenu for testing
		class Wmctile::WindowManagerRspec < Wmctile::WindowManager
			def dmenu items
				items.first.value
			end
		end
	end
	before(:each) do
		wm = Wmctile::WindowManagerRspec.new Wmctile::Settings.new
	end

	it 'gets dimensions and workspace number on init' do
		wm.instance_variable_get(:@w).should be_kind_of Integer
		wm.instance_variable_get(:@h).should be_kind_of Integer
		wm.instance_variable_get(:@workspace).should be_kind_of Integer
	end

	it 'has width/height getters' do
		wm.width(1).should eq wm.instance_variable_get(:@w)
		wm.width(0.5).should eq wm.instance_variable_get(:@w).to_f/2
		wm.height(1).should eq wm.instance_variable_get(:@h)
		wm.height(0.5).should eq wm.instance_variable_get(:@h).to_f/2
	end

	it 'is able to find a window' do
		router = Wmctile::Router.new
		active_win = router.get_active_window
		found_win = wm.find_window(active_win.get_name)
		
		found_win.instance_variable_get(:@id).should eq active_win.instance_variable_get(:@id)
		found_win.get_name.should eq active_win.get_name
	end

	it 'is able to ask for a window' do
		wm.ask_for_window.should be_kind_of Wmctile::Window
	end

	describe 'window list' do
		it 'builds windows list' do
			a = wm.build_win_list
			a.should be_kind_of Array
			a.first.should be_kind_of Wmctile::Window
		end
		it 'uses windows over again' do
			wm.build_win_list.should be wm.build_win_list
		end
		it 'filters workspaces' do
			all_windows = wm.build_win_list(false)
			workspace_windows = wm.build_win_list(true)

			all_windows.length.should be >= workspace_windows.length
		end
	end

	describe 'size calculation' do
		it 'can calculate snap' do
			wm.calculate_snap('left').should be_kind_of Hash
		end
	end
end