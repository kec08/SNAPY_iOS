//
//  AlbumCalendarView.swift
//  SNAPY_iOS
//
//  Created by 김은찬 on 4/9/26.
//

import SwiftUI

struct AlbumCalendarView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var photoStore = PhotoStore.shared

    // 날짜 탭 → 앨범 상세 push
    @State private var selectedAlbumDate: Date?
    @State private var showAlbumDetail = false

    @State private var months: [Date] = []

    private let calendar = Calendar.current
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 16), count: 7)
    private let dayLabels = ["일", "월", "화", "수", "목", "금", "토"]

    var body: some View {
        ZStack {
            Color.backgroundBlack.ignoresSafeArea()

            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 32) {
                        ForEach(months, id: \.self) { month in
                            monthView(for: month)
                                .id(month)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                    .padding(.bottom, 40)
                }
                .onChange(of: months) { _, newMonths in
                    if let last = newMonths.last {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            proxy.scrollTo(last, anchor: .bottom)
                        }
                    }
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.textWhite)
                }
            }
            ToolbarItem(placement: .principal) {
                Text("캘린더")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.textWhite)
            }
        }
        .toolbarBackground(Color.backgroundBlack, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .task {
            // 1. 월 배열 생성
            if months.isEmpty {
                months = generateMonths(count: 5)
            }
            // 2. 캘린더 전체 데이터를 한 번에 로드
            await photoStore.loadCalendar()
        }
        .navigationDestination(isPresented: $showAlbumDetail) {
            if let date = selectedAlbumDate {
                AlbumDateDetailView(date: date)
            }
        }
    }

    // MARK: - 월 단위 뷰

    @ViewBuilder
    private func monthView(for month: Date) -> some View {
        let year = calendar.component(.year, from: month)
        let monthNum = calendar.component(.month, from: month)

        VStack(alignment: .leading, spacing: 10) {
            Text("\(String(year))년 \(monthNum)월")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.textWhite)
                .padding(.bottom, 12)

            LazyVGrid(columns: columns, spacing: 4) {
                ForEach(dayLabels, id: \.self) { day in
                    Text(day)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.customGray300)
                        .frame(maxWidth: .infinity)
                }
            }

            LazyVGrid(columns: columns, spacing: 4) {
                let firstWeekday = firstWeekdayOfMonth(month)
                ForEach(0..<firstWeekday, id: \.self) { _ in
                    Color.clear
                        .frame(width: 50, height: 70)
                }

                let daysInMonth = numberOfDays(in: month)
                ForEach(1...daysInMonth, id: \.self) { day in
                    dayCell(year: year, month: monthNum, day: day)
                }
            }
        }
    }

    // MARK: - 날짜 한 칸

    @ViewBuilder
    private func dayCell(year: Int, month: Int, day: Int) -> some View {
        let dateComponents = DateComponents(year: year, month: month, day: day)
        let date = calendar.date(from: dateComponents) ?? Date()
        let isToday = calendar.isDateInToday(date)
        let isFuture = date > Date() && !isToday
        let thumbnail = thumbnailUrl(for: date)
        let hasAlbum = thumbnail != nil

        // 텍스트 색상: 오늘 → mainYellow, 미래 → gray300, 그 외 → white
        let textColor: Color = {
            if isToday { return .mainYellow }
            if isFuture { return .customGray300 }
            return .white
        }()

        Button {
            selectedAlbumDate = date
            showAlbumDetail = true
        } label: {
            ZStack {
                if let url = thumbnail {
                    AsyncImage(url: URL(string: url)) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFill()
                                .frame(width: 50, height: 70)
                        case .failure:
                            Color(white: 0.15)
                                .overlay(
                                    Image(systemName: "photo")
                                        .font(.system(size: 12))
                                        .foregroundColor(.gray)
                                )
                        case .empty:
                            Color(white: 0.15)
                                .overlay(ProgressView().scaleEffect(0.5))
                        @unknown default:
                            Color(white: 0.15)
                        }
                    }
                    .id(url)
                    .frame(width: 50, height: 70)
                    .clipped()
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                    .overlay {
                        Text("\(day)")
                            .font(.system(size: 14, weight: isToday ? .bold : .semibold))
                            .foregroundColor(textColor)
                            .shadow(color: .black.opacity(0.8), radius: 2)
                    }
                } else {
                    Color.clear
                        .frame(width: 50, height: 70)
                        .overlay {
                            Text("\(day)")
                                .font(.system(size: 14, weight: isToday ? .bold : .regular))
                                .foregroundColor(textColor)
                        }
                }
            }
            .frame(width: 50, height: 70)
        }
        .disabled(isFuture || (!hasAlbum && !isToday))
    }

    // MARK: - 헬퍼

    private func thumbnailUrl(for date: Date) -> String? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let dateString = formatter.string(from: date)
        return photoStore.calendarThumbnail(for: dateString)
    }

    private func firstWeekdayOfMonth(_ date: Date) -> Int {
        let components = calendar.dateComponents([.year, .month], from: date)
        let firstDay = calendar.date(from: components)!
        return calendar.component(.weekday, from: firstDay) - 1
    }

    private func numberOfDays(in date: Date) -> Int {
        calendar.range(of: .day, in: .month, for: date)?.count ?? 30
    }

    private func generateMonths(count: Int) -> [Date] {
        var result: [Date] = []
        for i in (0..<count).reversed() {
            if let date = calendar.date(byAdding: .month, value: -i, to: Date()) {
                result.append(date)
            }
        }
        return result
    }
}

#Preview {
    NavigationStack {
        AlbumCalendarView()
    }
}
